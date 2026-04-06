import { randomUUID } from 'node:crypto';
import { stat } from 'node:fs/promises';
import { basename, isAbsolute } from 'node:path';

import type { SupabaseClient } from '@supabase/supabase-js';

import type { RecordingRepository } from '../domain/contracts.js';
import type {
  AccessProfile,
  CreateRecordingInput,
  Project,
  ProjectMember,
  ProjectMemberRole,
  Recording,
  UserRecord,
} from '../domain/types.js';
import { config } from '../lib/config.js';
import {
  deserializeRecordingGraph,
  resolveStorageUserId,
  serializeRecordingGraph,
} from '../lib/persistence.js';
import {
  createSupabaseAdminClient,
  hasSupabasePersistenceConfig,
  uploadAudioToStorage,
} from '../lib/supabase-admin.js';
import { ServiceError } from '../services/service-errors.js';

const nowIso = () => new Date().toISOString();
const demoProjectId = 'project-demo';
const demoAdminProfileId = 'profile-admin';
const demoUserProfileId = 'profile-user';

export class MemoryRecordingRepository implements RecordingRepository {
  private readonly recordings = new Map<string, Recording>();
  private readonly projects = new Map<string, Project>();
  private readonly projectMembers = new Map<string, ProjectMember[]>();
  private readonly profiles = new Map<string, AccessProfile>();
  private readonly users = new Map<string, UserRecord>();
  private readonly supabase: SupabaseClient | null;
  private readonly persistenceMode: 'memory' | 'supabase';

  constructor(
    seed: Recording[] = [],
    options: { forcePersistenceMode?: 'memory' | 'supabase' } = {},
  ) {
    const wantsSupabase =
      options.forcePersistenceMode === 'supabase' ||
      (options.forcePersistenceMode == null &&
        (config.SUPABASE_PERSISTENCE_MODE === 'supabase' ||
          (config.SUPABASE_PERSISTENCE_MODE === 'auto' &&
            hasSupabasePersistenceConfig())));

    this.persistenceMode =
      options.forcePersistenceMode ?? (wantsSupabase ? 'supabase' : 'memory');
    this.supabase = wantsSupabase ? createSupabaseAdminClient() : null;

    if (this.persistenceMode === 'memory') {
      this.bootstrapMemory(seed);
    }
  }

  isSupabasePersistence(): boolean {
    return this.persistenceMode === 'supabase';
  }

  async list(userId: string, filters?: { query?: string; tag?: string; projectId?: string }): Promise<Recording[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listFromSupabase(userId, filters);
    }

    const allowedProjectIds = new Set((await this.listProjects(userId)).map((project) => project.id));
    const values = [...this.recordings.values()]
      .filter((recording) => allowedProjectIds.has(recording.projectId))
      .filter((recording) => matchesFilters(recording, filters))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));

    return structuredClone(values);
  }

  async listAllRecordings(filters?: {
    query?: string;
    projectId?: string;
    userId?: string;
    status?: Recording['status'];
  }): Promise<Recording[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listAllRecordingsFromSupabase(filters);
    }

    return [...this.recordings.values()]
      .filter((recording) => (filters?.projectId ? recording.projectId === filters.projectId : true))
      .filter((recording) => (filters?.userId ? recording.createdByUserId === filters.userId : true))
      .filter((recording) => (filters?.status ? recording.status === filters.status : true))
      .filter((recording) => matchesFilters(recording, { query: filters?.query }))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
      .map((recording) => structuredClone(recording));
  }

  async getById(recordingId: string, userId: string): Promise<Recording | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getFromSupabase(recordingId, userId);
    }

    const recording = this.recordings.get(recordingId);
    if (!recording) {
      return null;
    }

    const allowedProjectIds = new Set((await this.listProjects(userId)).map((project) => project.id));
    if (!allowedProjectIds.has(recording.projectId)) {
      return null;
    }

    return structuredClone(recording);
  }

  async getAnyById(recordingId: string): Promise<Recording | null> {
    if (this.persistenceMode === 'supabase') {
      return this.fetchGraph(recordingId, 'admin');
    }

    const recording = this.recordings.get(recordingId);
    return recording ? structuredClone(recording) : null;
  }

  async create(userId: string, input: CreateRecordingInput): Promise<Recording> {
    if (!input.projectId) {
      throw new ServiceError('projectId is required.', 400, 'project_id_required');
    }

    const timestamp = nowIso();
    const createdByUserId = input.createdByUserId ?? userId;
    const recording: Recording = {
      id: randomUUID(),
      userId: createdByUserId,
      createdByUserId,
      projectId: input.projectId,
      title: input.title,
      sourceType: input.sourceType,
      createdAt: timestamp,
      updatedAt: timestamp,
      durationMs: input.durationMs,
      audioPath: input.audioPath,
      transcriptionProvider: input.transcriptionProvider,
      transcriptionJobId: input.transcriptionJobId,
      transcriptionStartedAt: input.transcriptionStartedAt,
      transcriptionCompletedAt: input.transcriptionCompletedAt,
      status: 'uploaded',
      transcriptSegments: [],
      chatSession: {
        id: randomUUID(),
        recordingId: '',
        messages: [],
      },
    };
    recording.chatSession!.recordingId = recording.id;

    if (this.persistenceMode === 'supabase') {
      await this.ensureProjectMembership(userId, input.projectId);
      return this.upsertToSupabase(await maybeUploadOriginalAudio(recording));
    }

    await this.ensureProjectMembership(userId, input.projectId);
    this.recordings.set(recording.id, structuredClone(recording));
    return structuredClone(recording);
  }

  async update(recording: Recording): Promise<Recording> {
    const next = {
      ...recording,
      updatedAt: nowIso(),
    };

    if (this.persistenceMode === 'supabase') {
      return this.upsertToSupabase(await maybeUploadOriginalAudio(next));
    }

    this.recordings.set(next.id, structuredClone(next));
    return structuredClone(next);
  }

  async listProjects(userId: string): Promise<Project[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listProjectsFromSupabase(userId);
    }

    return [...this.projects.values()]
      .filter((project) => (this.projectMembers.get(project.id) ?? []).some((member) => member.userId === userId))
      .sort((left, right) => left.name.localeCompare(right.name))
      .map((project) => structuredClone(project));
  }

  async listAllProjects(filters?: { query?: string; status?: Project['status'] }): Promise<Project[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listAllProjectsFromSupabase(filters);
    }

    return [...this.projects.values()]
      .filter((project) => matchesProjectFilters(project, filters))
      .sort((left, right) => left.name.localeCompare(right.name))
      .map((project) => structuredClone(project));
  }

  async getProject(projectId: string, userId: string): Promise<Project | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getProjectFromSupabase(projectId, userId);
    }

    const project = this.projects.get(projectId);
    if (!project) {
      return null;
    }

    const members = this.projectMembers.get(projectId) ?? [];
    if (!members.some((member) => member.userId === userId)) {
      return null;
    }

    return structuredClone(project);
  }

  async getProjectById(projectId: string): Promise<Project | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getProjectByIdFromSupabase(projectId);
    }

    const project = this.projects.get(projectId);
    return project ? structuredClone(project) : null;
  }

  async createProject(userId: string, input: { name: string; slug: string }): Promise<Project> {
    if (this.persistenceMode === 'supabase') {
      return this.createProjectInSupabase(userId, input);
    }

    const timestamp = nowIso();
    const project: Project = {
      id: randomUUID(),
      name: input.name,
      slug: input.slug,
      status: 'active',
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    const member: ProjectMember = {
      projectId: project.id,
      userId,
      role: 'owner',
      createdAt: timestamp,
    };

    this.projects.set(project.id, project);
    this.projectMembers.set(project.id, [member]);
    return structuredClone(project);
  }

  async updateProject(
    userId: string,
    projectId: string,
    input: { name?: string; slug?: string; status?: Project['status'] },
  ): Promise<Project> {
    if (this.persistenceMode === 'supabase') {
      return this.updateProjectInSupabase(userId, projectId, input);
    }

    await this.ensureProjectOwner(userId, projectId);
    const current = this.projects.get(projectId);
    if (!current) {
      throw new ServiceError('Project not found.', 404, 'project_not_found');
    }

    const next: Project = {
      ...current,
      name: input.name ?? current.name,
      slug: input.slug ?? current.slug,
      status: input.status ?? current.status,
      updatedAt: nowIso(),
    };
    this.projects.set(projectId, next);
    return structuredClone(next);
  }

  async listProjectMembers(requesterUserId: string, projectId: string): Promise<ProjectMember[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listProjectMembersFromSupabase(requesterUserId, projectId);
    }

    await this.ensureProjectMembership(requesterUserId, projectId);
    return this.decorateProjectMembers(this.projectMembers.get(projectId) ?? []);
  }

  async listProjectMembersAdmin(projectId: string): Promise<ProjectMember[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listProjectMembersAdminFromSupabase(projectId);
    }

    return this.decorateProjectMembers(this.projectMembers.get(projectId) ?? []);
  }

  async addProjectMember(
    requesterUserId: string,
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember> {
    if (this.persistenceMode === 'supabase') {
      return this.addProjectMemberInSupabase(requesterUserId, projectId, member);
    }

    await this.ensureProjectOwner(requesterUserId, projectId);
    this.requireMemoryUser(member.userId);
    const members = this.projectMembers.get(projectId) ?? [];
    const existing = members.find((current) => current.userId === member.userId);
    if (existing) {
      return this.attachUserToMember(existing);
    }

    const projectMember: ProjectMember = {
      projectId,
      userId: member.userId,
      role: member.role,
      createdAt: nowIso(),
    };
    members.push(projectMember);
    this.projectMembers.set(projectId, members);
    return this.attachUserToMember(projectMember);
  }

  async addProjectMemberAdmin(
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember> {
    if (this.persistenceMode === 'supabase') {
      return this.addProjectMemberAdminInSupabase(projectId, member);
    }

    this.requireMemoryUser(member.userId);
    const members = this.projectMembers.get(projectId) ?? [];
    const existing = members.find((current) => current.userId === member.userId);
    if (existing) {
      return this.attachUserToMember(existing);
    }

    const projectMember: ProjectMember = {
      projectId,
      userId: member.userId,
      role: member.role,
      createdAt: nowIso(),
    };
    members.push(projectMember);
    this.projectMembers.set(projectId, members);
    return this.attachUserToMember(projectMember);
  }

  async removeProjectMember(requesterUserId: string, projectId: string, memberUserId: string): Promise<void> {
    if (this.persistenceMode === 'supabase') {
      await this.removeProjectMemberFromSupabase(requesterUserId, projectId, memberUserId);
      return;
    }

    await this.ensureProjectOwner(requesterUserId, projectId);
    const members = this.projectMembers.get(projectId) ?? [];
    this.projectMembers.set(
      projectId,
      members.filter((member) => member.userId !== memberUserId),
    );
  }

  async removeProjectMemberAdmin(projectId: string, memberUserId: string): Promise<void> {
    if (this.persistenceMode === 'supabase') {
      await this.removeProjectMemberAdminFromSupabase(projectId, memberUserId);
      return;
    }

    const members = this.projectMembers.get(projectId) ?? [];
    this.projectMembers.set(
      projectId,
      members.filter((member) => member.userId !== memberUserId),
    );
  }

  async listUsers(filters?: {
    query?: string;
    profileId?: string;
    isActive?: boolean;
  }): Promise<UserRecord[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listUsersFromSupabase(filters);
    }

    return [...this.users.values()]
      .filter((user) => matchesUserFilters(user, filters))
      .sort(compareUsers)
      .map((user) => structuredClone(user));
  }

  async getUserById(userId: string): Promise<UserRecord | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getUserByIdFromSupabase(userId);
    }

    const user = this.users.get(userId);
    return user ? structuredClone(user) : null;
  }

  async saveUser(input: {
    id: string;
    email?: string | null;
    fullName?: string | null;
    profileId?: string;
    isActive?: boolean;
  }): Promise<UserRecord> {
    if (this.persistenceMode === 'supabase') {
      return this.saveUserToSupabase(input);
    }

    const current = this.users.get(input.id);
    const profile = this.requireMemoryProfile(input.profileId ?? current?.profileId ?? demoUserProfileId);
    const timestamp = nowIso();
    const next: UserRecord = {
      id: input.id,
      email: input.email ?? current?.email ?? null,
      fullName: input.fullName ?? current?.fullName ?? null,
      profileId: profile.id,
      profileCode: profile.code,
      profileName: profile.name,
      isActive: input.isActive ?? current?.isActive ?? true,
      createdAt: current?.createdAt ?? timestamp,
      updatedAt: timestamp,
    };

    this.users.set(next.id, next);
    return structuredClone(next);
  }

  async listProfiles(filters?: { query?: string }): Promise<AccessProfile[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listProfilesFromSupabase(filters);
    }

    return [...this.profiles.values()]
      .filter((profile) => matchesProfileFilters(profile, filters))
      .sort((left, right) => left.name.localeCompare(right.name))
      .map((profile) => structuredClone(profile));
  }

  async getProfileById(profileId: string): Promise<AccessProfile | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getProfileByIdFromSupabase(profileId);
    }

    const profile = this.profiles.get(profileId);
    return profile ? structuredClone(profile) : null;
  }

  async getProfileByCode(code: string): Promise<AccessProfile | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getProfileByCodeFromSupabase(code);
    }

    const profile = [...this.profiles.values()].find((item) => item.code === code);
    return profile ? structuredClone(profile) : null;
  }

  async createProfile(input: {
    code: string;
    name: string;
    description?: string | null;
    isSystem?: boolean;
  }): Promise<AccessProfile> {
    if (this.persistenceMode === 'supabase') {
      return this.createProfileInSupabase(input);
    }

    if ([...this.profiles.values()].some((profile) => profile.code === input.code)) {
      throw new ServiceError('Profile code already exists.', 409, 'profile_code_conflict', {
        code: input.code,
      });
    }

    const timestamp = nowIso();
    const profile: AccessProfile = {
      id: randomUUID(),
      code: input.code,
      name: input.name,
      description: input.description ?? null,
      isSystem: input.isSystem ?? false,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    this.profiles.set(profile.id, profile);
    return structuredClone(profile);
  }

  async updateProfile(
    profileId: string,
    input: {
      code?: string;
      name?: string;
      description?: string | null;
    },
  ): Promise<AccessProfile> {
    if (this.persistenceMode === 'supabase') {
      return this.updateProfileInSupabase(profileId, input);
    }

    const current = this.requireMemoryProfile(profileId);
    if (
      input.code &&
      input.code !== current.code &&
      [...this.profiles.values()].some((profile) => profile.code === input.code)
    ) {
      throw new ServiceError('Profile code already exists.', 409, 'profile_code_conflict', {
        code: input.code,
      });
    }

    const next: AccessProfile = {
      ...current,
      code: input.code ?? current.code,
      name: input.name ?? current.name,
      description: input.description === undefined ? current.description ?? null : input.description,
      updatedAt: nowIso(),
    };

    this.profiles.set(profileId, next);
    for (const [userId, user] of this.users.entries()) {
      if (user.profileId !== profileId) {
        continue;
      }

      this.users.set(userId, {
        ...user,
        profileCode: next.code,
        profileName: next.name,
        updatedAt: nowIso(),
      });
    }

    return structuredClone(next);
  }

  async deleteProfile(profileId: string): Promise<void> {
    if (this.persistenceMode === 'supabase') {
      await this.deleteProfileFromSupabase(profileId);
      return;
    }

    const current = this.requireMemoryProfile(profileId);
    if (current.isSystem) {
      throw new ServiceError('System profiles cannot be deleted.', 400, 'profile_is_system');
    }

    if ([...this.users.values()].some((user) => user.profileId === profileId)) {
      throw new ServiceError('Profile is still assigned to users.', 409, 'profile_in_use');
    }

    this.profiles.delete(profileId);
  }

  private bootstrapMemory(seed: Recording[]) {
    const timestamp = nowIso();
    const adminProfile: AccessProfile = {
      id: demoAdminProfileId,
      code: 'admin',
      name: 'Administrador',
      description: 'Acesso administrativo completo ao backoffice.',
      isSystem: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    const userProfile: AccessProfile = {
      id: demoUserProfileId,
      code: 'user',
      name: 'Usuário',
      description: 'Usuário padrão do produto.',
      isSystem: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.profiles.set(adminProfile.id, adminProfile);
    this.profiles.set(userProfile.id, userProfile);

    this.users.set('demo-user', {
      id: 'demo-user',
      email: 'demo@example.com',
      fullName: 'Usuário demo',
      profileId: adminProfile.id,
      profileCode: adminProfile.code,
      profileName: adminProfile.name,
      isActive: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    });

    const defaultProject: Project = {
      id: demoProjectId,
      name: 'Projeto demo',
      slug: 'projeto-demo',
      status: 'active',
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    this.projects.set(defaultProject.id, defaultProject);

    const memberships = new Map<string, ProjectMember[]>();

    for (const rawRecording of seed) {
      const recording: Recording = {
        ...rawRecording,
        projectId: rawRecording.projectId == '' ? demoProjectId : rawRecording.projectId,
        createdByUserId: rawRecording.createdByUserId == '' ? rawRecording.userId : rawRecording.createdByUserId,
      };
      this.recordings.set(recording.id, structuredClone(recording));
      this.ensureMemoryUserSeed(recording.createdByUserId, timestamp);

      const projectId = recording.projectId;
      if (!this.projects.has(projectId)) {
        this.projects.set(projectId, {
          id: projectId,
          name: `Projeto ${projectId.substring(0, 6)}`,
          slug: `project-${projectId.substring(0, 6)}`,
          status: 'active',
          createdAt: timestamp,
          updatedAt: timestamp,
        });
      }

      const currentMembers = memberships.get(projectId) ?? [];
      if (!currentMembers.some((member) => member.userId === recording.createdByUserId)) {
        currentMembers.push({
          projectId,
          userId: recording.createdByUserId,
          role: currentMembers.length == 0 ? 'owner' : 'member',
          createdAt: timestamp,
        });
      }
      memberships.set(projectId, currentMembers);
    }

    if (!memberships.has(defaultProject.id)) {
      memberships.set(defaultProject.id, [
        {
          projectId: defaultProject.id,
          userId: 'demo-user',
          role: 'owner',
          createdAt: timestamp,
        },
      ]);
    }

    for (const [projectId, members] of memberships.entries()) {
      this.projectMembers.set(projectId, members);
    }
  }

  private ensureMemoryUserSeed(userId: string, timestamp: string) {
    if (this.users.has(userId)) {
      return;
    }

    const profile = this.requireMemoryProfile(demoUserProfileId);
    this.users.set(userId, {
      id: userId,
      email: null,
      fullName: null,
      profileId: profile.id,
      profileCode: profile.code,
      profileName: profile.name,
      isActive: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    });
  }

  private requireMemoryProfile(profileId: string): AccessProfile {
    const profile = this.profiles.get(profileId);
    if (!profile) {
      throw new ServiceError('Profile not found.', 404, 'profile_not_found', { profileId });
    }

    return profile;
  }

  private requireMemoryUser(userId: string): UserRecord {
    const user = this.users.get(userId);
    if (!user) {
      throw new ServiceError('User not found.', 404, 'user_not_found', { userId });
    }

    if (!user.isActive) {
      throw new ServiceError('User is inactive.', 409, 'user_inactive', { userId });
    }

    return user;
  }

  private attachUserToMember(member: ProjectMember): ProjectMember {
    const user = this.users.get(member.userId);
    return {
      ...structuredClone(member),
      ...(user ? { user: structuredClone(user) } : {}),
    };
  }

  private decorateProjectMembers(members: ProjectMember[]): ProjectMember[] {
    return members.map((member) => this.attachUserToMember(member));
  }

  private async listFromSupabase(
    userId: string,
    filters?: { query?: string; tag?: string; projectId?: string },
  ): Promise<Recording[]> {
    const storageUserId = resolveStorageUserId(userId);
    const supabase = this.ensureSupabaseClient();

    let membershipsQuery = supabase
      .from('project_members')
      .select('project_id')
      .eq('user_id', storageUserId);

    if (filters?.projectId) {
      membershipsQuery = membershipsQuery.eq('project_id', filters.projectId);
    }

    const { data: membershipRows, error: membershipError } = await membershipsQuery;
    if (membershipError) {
      throw wrapSupabaseError('Falha ao listar memberships.', membershipError);
    }

    const projectIds = (membershipRows ?? []).map((row) => String(row.project_id));
    if (projectIds.length == 0) {
      return [];
    }

    const { data, error } = await supabase
      .from('recordings')
      .select('id')
      .in('project_id', projectIds)
      .order('created_at', { ascending: false });

    if (error) {
      throw wrapSupabaseError('Falha ao listar gravacoes no Supabase.', error);
    }

    const recordings = await Promise.all(
      (data ?? []).map(async (row) => {
        const graph = await this.fetchGraph(String(row.id), userId);
        return graph;
      }),
    );

    return recordings
      .filter((recording): recording is Recording => recording !== null)
      .filter((recording) => matchesFilters(recording, filters))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
  }

  private async listAllRecordingsFromSupabase(filters?: {
    query?: string;
    projectId?: string;
    userId?: string;
    status?: Recording['status'];
  }): Promise<Recording[]> {
    const supabase = this.ensureSupabaseClient();

    let query = supabase.from('recordings').select('id').order('created_at', { ascending: false });
    if (filters?.projectId) {
      query = query.eq('project_id', filters.projectId);
    }
    if (filters?.userId) {
      query = query.eq('created_by_user_id', resolveStorageUserId(filters.userId));
    }
    if (filters?.status) {
      query = query.eq('status', filters.status);
    }

    const { data, error } = await query;
    if (error) {
      throw wrapSupabaseError('Falha ao listar gravacoes admin.', error);
    }

    const recordings = await Promise.all(
      (data ?? []).map(async (row) => {
        const payload = await this.fetchGraph(String(row.id), 'admin');
        return payload;
      }),
    );

    return recordings
      .filter((recording): recording is Recording => recording !== null)
      .filter((recording) => matchesFilters(recording, { query: filters?.query, projectId: filters?.projectId }))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
  }

  private async getFromSupabase(recordingId: string, userId: string): Promise<Recording | null> {
    const storageUserId = resolveStorageUserId(userId);
    const supabase = this.ensureSupabaseClient();

    const graph = await this.fetchGraph(recordingId, userId);
    if (!graph) {
      return null;
    }

    const { data, error } = await supabase
      .from('project_members')
      .select('project_id')
      .eq('project_id', graph.projectId)
      .eq('user_id', storageUserId)
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao validar acesso da gravacao.', error);
    }

    return data ? graph : null;
  }

  private async fetchGraph(recordingId: string, userId: string): Promise<Recording | null> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase.rpc('get_recording_graph', {
      recording_id: recordingId,
    });

    if (error) {
      throw wrapSupabaseError('Falha ao carregar grafo da gravacao no Supabase.', error);
    }

    if (!data) {
      return null;
    }

    return deserializeRecordingGraph(data, userId);
  }

  private async upsertToSupabase(recording: Recording): Promise<Recording> {
    const supabase = this.ensureSupabaseClient();
    const payload = serializeRecordingGraph(recording, resolveStorageUserId(recording.userId));

    const { data, error } = await supabase.rpc('upsert_recording_graph', {
      payload,
    });

    if (error) {
      throw wrapSupabaseError('Falha ao persistir grafo da gravacao no Supabase.', error);
    }

    return deserializeRecordingGraph(data, recording.userId);
  }

  private async listProjectsFromSupabase(userId: string): Promise<Project[]> {
    const supabase = this.ensureSupabaseClient();
    const storageUserId = resolveStorageUserId(userId);
    const { data, error } = await supabase
      .from('project_members')
      .select('projects(id,name,slug,status,created_at,updated_at)')
      .eq('user_id', storageUserId);

    if (error) {
      throw wrapSupabaseError('Falha ao listar projetos.', error);
    }

    return (data ?? [])
      .flatMap((row) => {
        const rawProject = (row as { projects?: unknown }).projects;
        const project = Array.isArray(rawProject) ? rawProject[0] : rawProject;
        if (!project || typeof project !== 'object') return [];
        const projectRecord = project as Record<string, unknown>;
        return [{
          id: String(projectRecord.id),
          name: String(projectRecord.name),
          slug: String(projectRecord.slug),
          status: projectRecord.status as Project['status'],
          createdAt: String(projectRecord.created_at),
          updatedAt: String(projectRecord.updated_at),
        }];
      })
      .sort((left, right) => left.name.localeCompare(right.name));
  }

  private async listAllProjectsFromSupabase(filters?: {
    query?: string;
    status?: Project['status'];
  }): Promise<Project[]> {
    const supabase = this.ensureSupabaseClient();
    let query = supabase
      .from('projects')
      .select('id,name,slug,status,created_at,updated_at')
      .order('name', { ascending: true });

    if (filters?.status) {
      query = query.eq('status', filters.status);
    }

    const { data, error } = await query;
    if (error) {
      throw wrapSupabaseError('Falha ao listar projetos admin.', error);
    }

    return (data ?? [])
      .map((project) => ({
        id: String(project.id),
        name: String(project.name),
        slug: String(project.slug),
        status: project.status as Project['status'],
        createdAt: String(project.created_at),
        updatedAt: String(project.updated_at),
      }))
      .filter((project) => matchesProjectFilters(project, filters));
  }

  private async getProjectFromSupabase(projectId: string, userId: string): Promise<Project | null> {
    const projects = await this.listProjectsFromSupabase(userId);
    return projects.find((project) => project.id === projectId) ?? null;
  }

  private async getProjectByIdFromSupabase(projectId: string): Promise<Project | null> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('projects')
      .select('id,name,slug,status,created_at,updated_at')
      .eq('id', projectId)
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao buscar projeto admin.', error);
    }

    if (!data) {
      return null;
    }

    return {
      id: String(data.id),
      name: String(data.name),
      slug: String(data.slug),
      status: data.status as Project['status'],
      createdAt: String(data.created_at),
      updatedAt: String(data.updated_at),
    };
  }

  private async createProjectInSupabase(userId: string, input: { name: string; slug: string }): Promise<Project> {
    const supabase = this.ensureSupabaseClient();
    const storageUserId = resolveStorageUserId(userId);
    const { data, error } = await supabase
      .from('projects')
      .insert({
        name: input.name,
        slug: input.slug,
        status: 'active',
      })
      .select('id,name,slug,status,created_at,updated_at')
      .single();

    if (error) {
      throw wrapSupabaseError('Falha ao criar projeto.', error);
    }

    const { error: memberError } = await supabase
      .from('project_members')
      .insert({
        project_id: data.id,
        user_id: storageUserId,
        role: 'owner',
      });

    if (memberError) {
      throw wrapSupabaseError('Falha ao criar membership do projeto.', memberError);
    }

    return {
      id: String(data.id),
      name: String(data.name),
      slug: String(data.slug),
      status: data.status as Project['status'],
      createdAt: String(data.created_at),
      updatedAt: String(data.updated_at),
    };
  }

  private async updateProjectInSupabase(
    userId: string,
    projectId: string,
    input: { name?: string; slug?: string; status?: Project['status'] },
  ): Promise<Project> {
    await this.ensureProjectOwner(userId, projectId);
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('projects')
      .update({
        ...(input.name != null ? { name: input.name } : {}),
        ...(input.slug != null ? { slug: input.slug } : {}),
        ...(input.status != null ? { status: input.status } : {}),
      })
      .eq('id', projectId)
      .select('id,name,slug,status,created_at,updated_at')
      .single();

    if (error) {
      throw wrapSupabaseError('Falha ao atualizar projeto.', error);
    }

    return {
      id: String(data.id),
      name: String(data.name),
      slug: String(data.slug),
      status: data.status as Project['status'],
      createdAt: String(data.created_at),
      updatedAt: String(data.updated_at),
    };
  }

  private async listProjectMembersFromSupabase(requesterUserId: string, projectId: string): Promise<ProjectMember[]> {
    await this.ensureProjectMembership(requesterUserId, projectId);
    return this.listProjectMembersAdminFromSupabase(projectId);
  }

  private async listProjectMembersAdminFromSupabase(projectId: string): Promise<ProjectMember[]> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('project_members')
      .select(
        'project_id,user_id,role,created_at,user:users!project_members_user_id_fkey(id,email,full_name,profile_id,is_active,created_at,updated_at,profile:profiles!users_profile_id_fkey(id,code,name,description,is_system,created_at,updated_at))',
      )
      .eq('project_id', projectId)
      .order('created_at', { ascending: true });

    if (error) {
      throw wrapSupabaseError('Falha ao listar membros do projeto.', error);
    }

    return (data ?? []).map((member) => {
      const user = mapUserRecord((member as { user?: unknown }).user);
      return {
        projectId: String(member.project_id),
        userId: String(member.user_id),
        role: member.role as ProjectMemberRole,
        createdAt: String(member.created_at),
        ...(user ? { user } : {}),
      };
    });
  }

  private async addProjectMemberInSupabase(
    requesterUserId: string,
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember> {
    await this.ensureProjectOwner(requesterUserId, projectId);
    return this.addProjectMemberAdminInSupabase(projectId, member);
  }

  private async addProjectMemberAdminInSupabase(
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember> {
    const existingUser = await this.getUserByIdFromSupabase(member.userId);
    if (!existingUser) {
      throw new ServiceError('User not found.', 404, 'user_not_found', { userId: member.userId });
    }

    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('project_members')
      .upsert({
        project_id: projectId,
        user_id: resolveStorageUserId(member.userId),
        role: member.role,
      })
      .select('project_id,user_id,role,created_at')
      .single();

    if (error) {
      throw wrapSupabaseError('Falha ao adicionar membro ao projeto.', error);
    }

    return {
      projectId: String(data.project_id),
      userId: member.userId,
      role: data.role as ProjectMemberRole,
      createdAt: String(data.created_at),
      user: existingUser,
    };
  }

  private async removeProjectMemberFromSupabase(
    requesterUserId: string,
    projectId: string,
    memberUserId: string,
  ): Promise<void> {
    await this.ensureProjectOwner(requesterUserId, projectId);
    await this.removeProjectMemberAdminFromSupabase(projectId, memberUserId);
  }

  private async removeProjectMemberAdminFromSupabase(
    projectId: string,
    memberUserId: string,
  ): Promise<void> {
    const supabase = this.ensureSupabaseClient();
    const { error } = await supabase
      .from('project_members')
      .delete()
      .eq('project_id', projectId)
      .eq('user_id', resolveStorageUserId(memberUserId));

    if (error) {
      throw wrapSupabaseError('Falha ao remover membro do projeto.', error);
    }
  }

  private async listUsersFromSupabase(filters?: {
    query?: string;
    profileId?: string;
    isActive?: boolean;
  }): Promise<UserRecord[]> {
    const supabase = this.ensureSupabaseClient();
    let query = supabase
      .from('users')
      .select(
        'id,email,full_name,profile_id,is_active,created_at,updated_at,profile:profiles!users_profile_id_fkey(id,code,name,description,is_system,created_at,updated_at)',
      )
      .order('full_name', { ascending: true })
      .order('email', { ascending: true });

    if (filters?.profileId) {
      query = query.eq('profile_id', filters.profileId);
    }

    if (filters?.isActive != null) {
      query = query.eq('is_active', filters.isActive);
    }

    const { data, error } = await query;
    if (error) {
      throw wrapSupabaseError('Falha ao listar usuários.', error);
    }

    return (data ?? [])
      .map((row) => mapUserRecord(row))
      .filter((user): user is UserRecord => user !== null)
      .filter((user) => matchesUserFilters(user, filters))
      .sort(compareUsers);
  }

  private async getUserByIdFromSupabase(userId: string): Promise<UserRecord | null> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('users')
      .select(
        'id,email,full_name,profile_id,is_active,created_at,updated_at,profile:profiles!users_profile_id_fkey(id,code,name,description,is_system,created_at,updated_at)',
      )
      .eq('id', resolveStorageUserId(userId))
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao buscar usuário.', error);
    }

    return mapUserRecord(data);
  }

  private async saveUserToSupabase(input: {
    id: string;
    email?: string | null;
    fullName?: string | null;
    profileId?: string;
    isActive?: boolean;
  }): Promise<UserRecord> {
    const current = await this.getUserByIdFromSupabase(input.id);
    const fallbackProfile = current?.profileId
      ? await this.getProfileByIdFromSupabase(current.profileId)
      : await this.getProfileByCodeFromSupabase('user');
    const resolvedProfileId = input.profileId ?? fallbackProfile?.id;

    if (!resolvedProfileId) {
      throw new ServiceError('Default profile not found.', 500, 'profile_default_missing');
    }

    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('users')
      .upsert({
        id: resolveStorageUserId(input.id),
        email: input.email === undefined ? current?.email ?? null : input.email,
        full_name: input.fullName === undefined ? current?.fullName ?? null : input.fullName,
        profile_id: resolvedProfileId,
        is_active: input.isActive ?? current?.isActive ?? true,
      })
      .select(
        'id,email,full_name,profile_id,is_active,created_at,updated_at,profile:profiles!users_profile_id_fkey(id,code,name,description,is_system,created_at,updated_at)',
      )
      .single();

    if (error) {
      throw wrapSupabaseError('Falha ao salvar usuário.', error);
    }

    const user = mapUserRecord(data);
    if (!user) {
      throw new ServiceError('User payload is invalid.', 500, 'user_payload_invalid');
    }

    return user;
  }

  private async listProfilesFromSupabase(filters?: { query?: string }): Promise<AccessProfile[]> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('id,code,name,description,is_system,created_at,updated_at')
      .order('name', { ascending: true });

    if (error) {
      throw wrapSupabaseError('Falha ao listar perfis.', error);
    }

    return (data ?? [])
      .map((row) => mapAccessProfile(row))
      .filter((profile): profile is AccessProfile => profile !== null)
      .filter((profile) => matchesProfileFilters(profile, filters));
  }

  private async getProfileByIdFromSupabase(profileId: string): Promise<AccessProfile | null> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('id,code,name,description,is_system,created_at,updated_at')
      .eq('id', profileId)
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao buscar perfil.', error);
    }

    return mapAccessProfile(data);
  }

  private async getProfileByCodeFromSupabase(code: string): Promise<AccessProfile | null> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('id,code,name,description,is_system,created_at,updated_at')
      .eq('code', code)
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao buscar perfil por código.', error);
    }

    return mapAccessProfile(data);
  }

  private async createProfileInSupabase(input: {
    code: string;
    name: string;
    description?: string | null;
    isSystem?: boolean;
  }): Promise<AccessProfile> {
    const existing = await this.getProfileByCodeFromSupabase(input.code);
    if (existing) {
      throw new ServiceError('Profile code already exists.', 409, 'profile_code_conflict', {
        code: input.code,
      });
    }

    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .insert({
        code: input.code,
        name: input.name,
        description: input.description ?? null,
        is_system: input.isSystem ?? false,
      })
      .select('id,code,name,description,is_system,created_at,updated_at')
      .single();

    if (error) {
      throw wrapSupabaseError('Falha ao criar perfil.', error);
    }

    const profile = mapAccessProfile(data);
    if (!profile) {
      throw new ServiceError('Profile payload is invalid.', 500, 'profile_payload_invalid');
    }

    return profile;
  }

  private async updateProfileInSupabase(
    profileId: string,
    input: {
      code?: string;
      name?: string;
      description?: string | null;
    },
  ): Promise<AccessProfile> {
    const current = await this.getProfileByIdFromSupabase(profileId);
    if (!current) {
      throw new ServiceError('Profile not found.', 404, 'profile_not_found', { profileId });
    }

    if (current.isSystem && input.code && input.code !== current.code) {
      throw new ServiceError('System profiles cannot change code.', 400, 'profile_is_system');
    }

    if (input.code && input.code !== current.code) {
      const existing = await this.getProfileByCodeFromSupabase(input.code);
      if (existing) {
        throw new ServiceError('Profile code already exists.', 409, 'profile_code_conflict', {
          code: input.code,
        });
      }
    }

    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .update({
        ...(input.code != null ? { code: input.code } : {}),
        ...(input.name != null ? { name: input.name } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
      })
      .eq('id', profileId)
      .select('id,code,name,description,is_system,created_at,updated_at')
      .single();

    if (error) {
      throw wrapSupabaseError('Falha ao atualizar perfil.', error);
    }

    const profile = mapAccessProfile(data);
    if (!profile) {
      throw new ServiceError('Profile payload is invalid.', 500, 'profile_payload_invalid');
    }

    return profile;
  }

  private async deleteProfileFromSupabase(profileId: string): Promise<void> {
    const current = await this.getProfileByIdFromSupabase(profileId);
    if (!current) {
      throw new ServiceError('Profile not found.', 404, 'profile_not_found', { profileId });
    }

    if (current.isSystem) {
      throw new ServiceError('System profiles cannot be deleted.', 400, 'profile_is_system');
    }

    const supabase = this.ensureSupabaseClient();
    const { count, error: countError } = await supabase
      .from('users')
      .select('id', { count: 'exact', head: true })
      .eq('profile_id', profileId);

    if (countError) {
      throw wrapSupabaseError('Falha ao validar uso do perfil.', countError);
    }

    if ((count ?? 0) > 0) {
      throw new ServiceError('Profile is still assigned to users.', 409, 'profile_in_use');
    }

    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', profileId);

    if (error) {
      throw wrapSupabaseError('Falha ao remover perfil.', error);
    }
  }

  private async ensureProjectMembership(userId: string, projectId: string): Promise<void> {
    const isMember = this.persistenceMode === 'supabase'
      ? await this.hasProjectMembershipInSupabase(userId, projectId)
      : (this.projectMembers.get(projectId) ?? []).some(
          (member) => member.userId === userId || member.userId === resolveStorageUserId(userId),
        );

    if (!isMember) {
      throw new ServiceError('Project access denied.', 403, 'project_access_denied', { projectId });
    }
  }

  private async ensureProjectOwner(userId: string, projectId: string): Promise<void> {
    const isOwner = this.persistenceMode === 'supabase'
      ? await this.hasProjectOwnerRoleInSupabase(userId, projectId)
      : (this.projectMembers.get(projectId) ?? []).some(
          (member) =>
            (member.userId === userId || member.userId === resolveStorageUserId(userId)) &&
            member.role === 'owner',
        );

    if (!isOwner) {
      throw new ServiceError('Project owner access required.', 403, 'project_owner_required', { projectId });
    }
  }

  private async hasProjectMembershipInSupabase(userId: string, projectId: string): Promise<boolean> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('project_members')
      .select('project_id')
      .eq('project_id', projectId)
      .eq('user_id', resolveStorageUserId(userId))
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao validar membership do projeto.', error);
    }

    return Boolean(data);
  }

  private async hasProjectOwnerRoleInSupabase(userId: string, projectId: string): Promise<boolean> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase
      .from('project_members')
      .select('project_id')
      .eq('project_id', projectId)
      .eq('user_id', resolveStorageUserId(userId))
      .eq('role', 'owner')
      .maybeSingle();

    if (error) {
      throw wrapSupabaseError('Falha ao validar ownership do projeto.', error);
    }

    return Boolean(data);
  }

  private ensureSupabaseClient(): SupabaseClient {
    if (!this.supabase) {
      throw new Error('Supabase client is not configured');
    }

    return this.supabase;
  }
}

async function maybeUploadOriginalAudio(recording: Recording): Promise<Recording> {
  const audioPath = recording.audioPath;
  if (!audioPath || !isAbsolute(audioPath)) {
    return recording;
  }

  const fileStats = await stat(audioPath).catch(() => null);
  if (!fileStats || !fileStats.isFile()) {
    return recording;
  }

  const objectPath = `${recording.projectId}/${recording.id}/${basename(audioPath)}`;
  await uploadAudioToStorage({
    objectPath,
    filePath: audioPath,
  });

  return {
    ...recording,
    audioPath: objectPath,
  };
}

function matchesFilters(
  recording: Recording,
  filters?: { query?: string; tag?: string; projectId?: string },
): boolean {
  if (!filters) {
    return true;
  }

  if (filters.projectId && recording.projectId !== filters.projectId) {
    return false;
  }

  const query = filters.query?.trim().toLowerCase();
  if (query) {
    const haystack = [
      recording.title,
      recording.summary?.overview ?? '',
      recording.noteArtifact?.tags.join(' ') ?? '',
      recording.transcriptSegments.map((segment) => segment.text).join(' '),
    ]
      .join(' ')
      .toLowerCase();

    if (!haystack.includes(query)) {
      return false;
    }
  }

  const tag = filters.tag?.trim().toLowerCase();
  if (tag) {
    const tags = recording.noteArtifact?.tags ?? [];
    if (!tags.some((value) => value.toLowerCase() === tag)) {
      return false;
    }
  }

  return true;
}

function matchesProjectFilters(
  project: Project,
  filters?: { query?: string; status?: Project['status'] },
): boolean {
  if (!filters) {
    return true;
  }

  if (filters.status && project.status !== filters.status) {
    return false;
  }

  const query = filters.query?.trim().toLowerCase();
  if (!query) {
    return true;
  }

  return [project.name, project.slug, project.id].some((value) => value.toLowerCase().includes(query));
}

function matchesUserFilters(
  user: UserRecord,
  filters?: {
    query?: string;
    profileId?: string;
    isActive?: boolean;
  },
): boolean {
  if (!filters) {
    return true;
  }

  if (filters.profileId && user.profileId !== filters.profileId) {
    return false;
  }

  if (filters.isActive != null && user.isActive !== filters.isActive) {
    return false;
  }

  const query = filters.query?.trim().toLowerCase();
  if (!query) {
    return true;
  }

  return [
    user.id,
    user.email ?? '',
    user.fullName ?? '',
    user.profileCode,
    user.profileName,
  ].some((value) => value.toLowerCase().includes(query));
}

function matchesProfileFilters(profile: AccessProfile, filters?: { query?: string }): boolean {
  const query = filters?.query?.trim().toLowerCase();
  if (!query) {
    return true;
  }

  return [
    profile.code,
    profile.name,
    profile.description ?? '',
  ].some((value) => value.toLowerCase().includes(query));
}

function compareUsers(left: UserRecord, right: UserRecord): number {
  const leftLabel = (left.fullName ?? left.email ?? left.id).toLowerCase();
  const rightLabel = (right.fullName ?? right.email ?? right.id).toLowerCase();
  return leftLabel.localeCompare(rightLabel);
}

function unwrapRelation(value: unknown): Record<string, unknown> | null {
  if (Array.isArray(value)) {
    return value.length > 0 && value[0] && typeof value[0] === 'object'
      ? (value[0] as Record<string, unknown>)
      : null;
  }

  return value && typeof value === 'object' ? (value as Record<string, unknown>) : null;
}

function mapAccessProfile(row: unknown): AccessProfile | null {
  const record = unwrapRelation(row);
  if (!record) {
    return null;
  }

  return {
    id: String(record.id),
    code: String(record.code),
    name: String(record.name),
    description: record.description == null ? null : String(record.description),
    isSystem: Boolean(record.is_system),
    createdAt: String(record.created_at),
    updatedAt: String(record.updated_at),
  };
}

function mapUserRecord(row: unknown): UserRecord | null {
  const record = unwrapRelation(row);
  if (!record) {
    return null;
  }

  const profile = mapAccessProfile(record.profile);
  if (!profile) {
    return null;
  }

  return {
    id: String(record.id),
    email: record.email == null ? null : String(record.email),
    fullName: record.full_name == null ? null : String(record.full_name),
    profileId: String(record.profile_id),
    profileCode: profile.code,
    profileName: profile.name,
    isActive: Boolean(record.is_active),
    createdAt: String(record.created_at),
    updatedAt: String(record.updated_at),
  };
}

function wrapSupabaseError(message: string, error: unknown): ServiceError {
  if (error instanceof ServiceError) {
    return error;
  }

  const details = typeof error === 'object' && error !== null
    ? {
        code: 'code' in error ? (error as { code?: unknown }).code : undefined,
        details: 'details' in error ? (error as { details?: unknown }).details : undefined,
        hint: 'hint' in error ? (error as { hint?: unknown }).hint : undefined,
      }
    : undefined;

  const errorMessage = typeof error === 'object' && error !== null && 'message' in error
    ? String((error as { message?: unknown }).message)
    : String(error);

  return new ServiceError(
    `${message} ${errorMessage}`,
    502,
    'supabase_operation_failed',
    details,
  );
}
