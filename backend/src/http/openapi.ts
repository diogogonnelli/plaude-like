export function buildOpenApiDocument(baseUrl: string) {
  return {
    openapi: '3.1.0',
    info: {
      title: 'Plaude Like API',
      version: '1.0.0',
      description:
        'API HTTP autenticada para projetos, gravações, chat e superfícies administrativas operacionais.',
    },
    servers: [
      {
        url: baseUrl,
      },
    ],
    tags: [
      { name: 'System', description: 'Healthcheck e metadata da API' },
      { name: 'Projects', description: 'Projetos (jobs) e memberships' },
      { name: 'Recordings', description: 'Operacoes sobre gravacoes e notas' },
      { name: 'Chat', description: 'Perguntas sobre uma nota pronta' },
      { name: 'Export', description: 'Exportacao textual da nota' },
      { name: 'Webhooks', description: 'Callbacks de provedores externos' },
      { name: 'Admin', description: 'Superficie administrativa e operacional baseada em public.users + public.profiles' },
    ],
    security: [
      {
        bearerAuth: [],
      },
    ],
    paths: {
      '/health': {
        get: {
          tags: ['System'],
          summary: 'Healthcheck do backend',
          security: [],
          responses: {
            '200': {
              description: 'Servico disponivel',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      ok: { type: 'boolean' },
                      service: { type: 'string' },
                    },
                    required: ['ok', 'service'],
                  },
                },
              },
            },
          },
        },
      },
      '/recordings': {
        get: {
          tags: ['Recordings'],
          summary: 'Lista gravacoes do usuario atual',
          parameters: [
            {
              in: 'query',
              name: 'query',
              required: false,
              schema: { type: 'string' },
            },
            {
              in: 'query',
              name: 'tag',
              required: false,
              schema: { type: 'string' },
            },
            {
              in: 'query',
              name: 'projectId',
              required: false,
              schema: { type: 'string' },
            },
            {
              in: 'query',
              name: '_ts',
              required: false,
              schema: { type: 'string' },
              description: 'Parametro opcional de cache-busting usado pelo frontend.',
            },
          ],
          responses: {
            '200': {
              description: 'Lista de gravacoes',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: {
                        type: 'array',
                        items: { $ref: '#/components/schemas/Recording' },
                      },
                    },
                    required: ['data'],
                  },
                },
              },
            },
          },
        },
        post: {
          tags: ['Recordings'],
          summary: 'Cria uma gravacao via JSON',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    title: { type: 'string' },
                    projectId: { type: 'string' },
                    sourceType: { type: 'string', enum: ['microphone', 'upload', 'desktop_meeting'] },
                    captureMetadata: { $ref: '#/components/schemas/CaptureMetadata' },
                    durationMs: { type: 'integer' },
                    audioPath: { type: 'string' },
                  },
                  required: ['title', 'projectId', 'sourceType'],
                },
              },
            },
          },
          responses: {
            '201': {
              description: 'Gravacao criada',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: { $ref: '#/components/schemas/Recording' },
                      upload: {
                        type: 'object',
                        properties: {
                          bucket: { type: 'string' },
                          objectPath: { type: 'string' },
                        },
                      },
                    },
                  },
                },
              },
            },
            '400': { $ref: '#/components/responses/ValidationError' },
          },
        },
      },
      '/recordings/upload': {
        post: {
          tags: ['Recordings'],
          summary: 'Faz upload real de audio e inicia transcricao assincrona',
          requestBody: {
            required: true,
            content: {
              'multipart/form-data': {
                schema: {
                  type: 'object',
                  properties: {
                    file: { type: 'string', format: 'binary' },
                    title: { type: 'string' },
                    projectId: { type: 'string' },
                    sourceType: { type: 'string', enum: ['microphone', 'upload', 'desktop_meeting'] },
                    captureMetadata: { type: 'string', description: 'JSON stringificado com metadata da captura desktop.' },
                    durationMs: { type: 'integer' },
                  },
                  required: ['file', 'title', 'projectId'],
                },
              },
            },
          },
          responses: {
            '201': {
              description: 'Gravacao criada e transcricao iniciada',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: { $ref: '#/components/schemas/Recording' },
                    },
                    required: ['data'],
                  },
                },
              },
            },
            '400': { $ref: '#/components/responses/ValidationError' },
          },
        },
      },
      '/recordings/{id}': {
        get: {
          tags: ['Recordings'],
          summary: 'Busca uma gravacao por id',
          parameters: [
            {
              in: 'path',
              name: 'id',
              required: true,
              schema: { type: 'string' },
            },
            {
              in: 'header',
              name: 'x-user-id',
              required: false,
              schema: { type: 'string' },
            },
          ],
          responses: {
            '200': {
              description: 'Gravacao encontrada',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: { $ref: '#/components/schemas/Recording' },
                    },
                    required: ['data'],
                  },
                },
              },
            },
            '404': { $ref: '#/components/responses/NotFoundError' },
          },
        },
      },
      '/recordings/{id}/process': {
        post: {
          tags: ['Recordings'],
          summary: 'Processa uma gravacao a partir de transcriptText',
          parameters: [
            {
              in: 'path',
              name: 'id',
              required: true,
              schema: { type: 'string' },
            },
          ],
          requestBody: {
            required: false,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    transcriptText: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: {
            '200': {
              description: 'Gravacao processada',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: { $ref: '#/components/schemas/Recording' },
                    },
                    required: ['data'],
                  },
                },
              },
            },
          },
        },
      },
      '/projects': {
        get: {
          tags: ['Projects'],
          summary: 'Lista projetos do usuario atual',
          responses: {
            '200': {
              description: 'Lista de projetos',
            },
          },
        },
      },
      '/projects/{id}': {
        get: {
          tags: ['Projects'],
          summary: 'Busca um projeto por id',
          parameters: [
            {
              in: 'path',
              name: 'id',
              required: true,
              schema: { type: 'string' },
            },
          ],
          responses: {
            '200': {
              description: 'Projeto encontrado',
            },
            '404': { $ref: '#/components/responses/NotFoundError' },
          },
        },
      },
      '/recordings/{id}/chat': {
        post: {
          tags: ['Chat'],
          summary: 'Envia uma pergunta sobre a nota',
          parameters: [
            {
              in: 'path',
              name: 'id',
              required: true,
              schema: { type: 'string' },
            },
          ],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    question: { type: 'string' },
                  },
                  required: ['question'],
                },
              },
            },
          },
          responses: {
            '200': {
              description: 'Resposta do chat',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      recordingId: { type: 'string' },
                      answer: { $ref: '#/components/schemas/ChatMessage' },
                      session: { $ref: '#/components/schemas/ChatSession' },
                    },
                  },
                },
              },
            },
          },
        },
      },
      '/recordings/{id}/export': {
        post: {
          tags: ['Export'],
          summary: 'Exporta a nota em txt ou md',
          parameters: [
            {
              in: 'path',
              name: 'id',
              required: true,
              schema: { type: 'string' },
            },
          ],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    format: { type: 'string', enum: ['txt', 'md'] },
                  },
                  required: ['format'],
                },
              },
            },
          },
          responses: {
            '200': {
              description: 'Arquivo exportado em memoria',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      data: { $ref: '#/components/schemas/ExportArtifact' },
                    },
                    required: ['data'],
                  },
                },
              },
            },
          },
        },
      },
      '/webhooks/transcription': {
        post: {
          tags: ['Webhooks'],
          summary: 'Webhook generico de transcricao',
          security: [],
          responses: {
            '202': {
              description: 'Webhook aceito',
            },
          },
        },
      },
      '/webhooks/assemblyai': {
        post: {
          tags: ['Webhooks'],
          summary: 'Webhook especifico do AssemblyAI',
          security: [],
          parameters: [
            {
              in: 'query',
              name: 'recordingId',
              required: true,
              schema: { type: 'string' },
            },
            {
              in: 'query',
              name: 'userId',
              required: true,
              schema: { type: 'string' },
            },
          ],
          responses: {
            '202': {
              description: 'Webhook aceito',
            },
          },
        },
      },
      '/admin/dashboard': {
        get: {
          tags: ['Admin'],
          summary: 'Resumo operacional do backoffice',
          responses: { '200': { description: 'Dashboard operacional' } },
        },
      },
      '/admin/me': {
        get: {
          tags: ['Admin'],
          summary: 'Valida a sessao administrativa atual e retorna o perfil efetivo',
          responses: { '200': { description: 'Sessao admin validada' } },
        },
      },
      '/admin/profiles': {
        get: {
          tags: ['Admin'],
          summary: 'Lista perfis de acesso',
          parameters: [
            { in: 'query', name: 'query', required: false, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Lista de perfis' } },
        },
        post: {
          tags: ['Admin'],
          summary: 'Cria perfil de acesso',
          responses: { '201': { description: 'Perfil criado' } },
        },
      },
      '/admin/profiles/{id}': {
        patch: {
          tags: ['Admin'],
          summary: 'Atualiza perfil de acesso',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Perfil atualizado' } },
        },
        delete: {
          tags: ['Admin'],
          summary: 'Remove perfil de acesso',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '204': { description: 'Perfil removido' } },
        },
      },
      '/admin/users': {
        get: {
          tags: ['Admin'],
          summary: 'Lista usuarios do diretório administrativo',
          parameters: [
            { in: 'query', name: 'query', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'profileId', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'isActive', required: false, schema: { type: 'boolean' } },
          ],
          responses: { '200': { description: 'Lista de usuarios' } },
        },
        post: {
          tags: ['Admin'],
          summary: 'Cria usuario e vincula perfil',
          responses: { '201': { description: 'Usuario criado' } },
        },
      },
      '/admin/users/{id}': {
        patch: {
          tags: ['Admin'],
          summary: 'Atualiza usuario administrativo',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Usuario atualizado' } },
        },
      },
      '/admin/projects': {
        get: {
          tags: ['Admin'],
          summary: 'Lista projetos para o admin',
          parameters: [
            { in: 'query', name: 'query', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'status', required: false, schema: { type: 'string', enum: ['active', 'archived'] } },
          ],
          responses: { '200': { description: 'Lista de projetos admin' } },
        },
        post: {
          tags: ['Admin'],
          summary: 'Cria projeto',
          responses: { '201': { description: 'Projeto criado' } },
        },
      },
      '/admin/projects/{id}': {
        get: {
          tags: ['Admin'],
          summary: 'Busca um projeto por id para o admin',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Projeto encontrado' } },
        },
        patch: {
          tags: ['Admin'],
          summary: 'Atualiza projeto',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Projeto atualizado' } },
        },
      },
      '/admin/projects/{id}/members': {
        get: {
          tags: ['Admin'],
          summary: 'Lista membros do projeto',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Lista de membros' } },
        },
        post: {
          tags: ['Admin'],
          summary: 'Adiciona membro ao projeto',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '201': { description: 'Membro adicionado' } },
        },
      },
      '/admin/projects/{id}/members/{userId}': {
        delete: {
          tags: ['Admin'],
          summary: 'Remove membro do projeto',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
            { in: 'path', name: 'userId', required: true, schema: { type: 'string' } },
          ],
          responses: { '204': { description: 'Membro removido' } },
        },
      },
      '/admin/recordings': {
        get: {
          tags: ['Admin'],
          summary: 'Lista gravacoes para o backoffice',
          parameters: [
            { in: 'query', name: 'query', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'projectId', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'userId', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'sourceApp', required: false, schema: { type: 'string', enum: ['teams', 'zoom', 'meet', 'system_audio'] } },
            { in: 'query', name: 'platform', required: false, schema: { type: 'string', enum: ['windows', 'macos'] } },
            {
              in: 'query',
              name: 'status',
              required: false,
              schema: {
                type: 'string',
                enum: ['uploaded', 'processing_transcript', 'processing_summary', 'indexing', 'ready', 'failed'],
              },
            },
          ],
          responses: { '200': { description: 'Lista de gravacoes admin' } },
        },
      },
      '/admin/recordings/{id}': {
        get: {
          tags: ['Admin'],
          summary: 'Busca detalhe de gravacao para o backoffice',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Detalhe da gravacao' } },
        },
      },
      '/admin/recordings/{id}/reprocess': {
        post: {
          tags: ['Admin'],
          summary: 'Reprocessa uma gravacao',
          parameters: [
            { in: 'path', name: 'id', required: true, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'Gravacao reenfileirada/processada' } },
        },
      },
      '/admin/jobs': {
        get: {
          tags: ['Admin'],
          summary: 'Lista jobs operacionais de transcricao',
          parameters: [
            { in: 'query', name: 'query', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'projectId', required: false, schema: { type: 'string' } },
            { in: 'query', name: 'sourceApp', required: false, schema: { type: 'string', enum: ['teams', 'zoom', 'meet', 'system_audio'] } },
            { in: 'query', name: 'platform', required: false, schema: { type: 'string', enum: ['windows', 'macos'] } },
            {
              in: 'query',
              name: 'status',
              required: false,
              schema: {
                type: 'string',
                enum: ['uploaded', 'processing_transcript', 'processing_summary', 'indexing', 'ready', 'failed'],
              },
            },
          ],
          responses: { '200': { description: 'Lista de jobs' } },
        },
      },
      '/admin/providers': {
        get: {
          tags: ['Admin'],
          summary: 'Consulta configuracao de providers',
          responses: { '200': { description: 'Providers atuais' } },
        },
        patch: {
          tags: ['Admin'],
          summary: 'Solicita alteracao de providers',
          responses: { '200': { description: 'Solicitacao registrada' } },
        },
      },
    },
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description:
            'Use o access token do Supabase Auth. O header x-user-id fica apenas como fallback de desenvolvimento quando auth nao estiver configurada.',
        },
      },
      responses: {
        ValidationError: {
          description: 'Erro de validacao',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ErrorResponse' },
            },
          },
        },
        NotFoundError: {
          description: 'Recurso nao encontrado',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/ErrorResponse' },
            },
          },
        },
      },
      schemas: {
        ErrorResponse: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            code: { type: 'string' },
            details: { type: 'object', additionalProperties: true },
          },
          required: ['error', 'code'],
        },
        TranscriptSegment: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            recordingId: { type: 'string' },
            speakerLabel: { type: 'string' },
            startMs: { type: 'integer' },
            endMs: { type: 'integer' },
            text: { type: 'string' },
          },
        },
        Summary: {
          type: 'object',
          properties: {
            overview: { type: 'string' },
            chapters: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  heading: { type: 'string' },
                  body: { type: 'string' },
                },
              },
            },
          },
        },
        NoteArtifact: {
          type: 'object',
          properties: {
            title: { type: 'string' },
            tags: { type: 'array', items: { type: 'string' } },
            highlights: { type: 'array', items: { type: 'string' } },
            actionItems: { type: 'array', items: { type: 'string' } },
          },
        },
        CaptureMetadata: {
          type: 'object',
          properties: {
            sourceApp: { type: 'string', enum: ['teams', 'zoom', 'meet', 'system_audio'] },
            platform: { type: 'string', enum: ['windows', 'macos'] },
            captureMode: { type: 'string', enum: ['system_and_mic'] },
            helperVersion: { type: 'string' },
            windowTitle: { type: 'string', nullable: true },
          },
          required: ['sourceApp', 'platform', 'captureMode', 'helperVersion'],
        },
        ChatCitation: {
          type: 'object',
          properties: {
            segmentId: { type: 'string' },
            startMs: { type: 'integer' },
            endMs: { type: 'integer' },
            quote: { type: 'string' },
          },
        },
        ChatMessage: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            role: { type: 'string', enum: ['user', 'assistant'] },
            content: { type: 'string' },
            createdAt: { type: 'string' },
            citations: {
              type: 'array',
              items: { $ref: '#/components/schemas/ChatCitation' },
            },
          },
        },
        ChatSession: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            recordingId: { type: 'string' },
            messages: {
              type: 'array',
              items: { $ref: '#/components/schemas/ChatMessage' },
            },
          },
        },
        ExportArtifact: {
          type: 'object',
          properties: {
            format: { type: 'string', enum: ['txt', 'md'] },
            fileName: { type: 'string' },
            contentType: { type: 'string' },
            body: { type: 'string' },
          },
        },
        Recording: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            userId: { type: 'string' },
            createdByUserId: { type: 'string' },
            projectId: { type: 'string' },
            title: { type: 'string' },
            sourceType: { type: 'string', enum: ['microphone', 'upload', 'desktop_meeting'] },
            captureMetadata: {
              oneOf: [
                { $ref: '#/components/schemas/CaptureMetadata' },
                { type: 'null' },
              ],
            },
            status: {
              type: 'string',
              enum: [
                'uploaded',
                'processing_transcript',
                'processing_summary',
                'indexing',
                'ready',
                'failed',
              ],
            },
            createdAt: { type: 'string' },
            updatedAt: { type: 'string' },
            durationMs: { type: 'integer', nullable: true },
            audioPath: { type: 'string', nullable: true },
            transcriptionProvider: { type: 'string', nullable: true },
            transcriptionJobId: { type: 'string', nullable: true },
            transcriptionStartedAt: { type: 'string', nullable: true },
            transcriptionCompletedAt: { type: 'string', nullable: true },
            transcriptSegments: {
              type: 'array',
              items: { $ref: '#/components/schemas/TranscriptSegment' },
            },
            summary: {
              oneOf: [
                { $ref: '#/components/schemas/Summary' },
                { type: 'null' },
              ],
            },
            noteArtifact: {
              oneOf: [
                { $ref: '#/components/schemas/NoteArtifact' },
                { type: 'null' },
              ],
            },
            chatSession: {
              oneOf: [
                { $ref: '#/components/schemas/ChatSession' },
                { type: 'null' },
              ],
            },
            lastError: { type: 'string', nullable: true },
          },
        },
        Project: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            slug: { type: 'string' },
            status: { type: 'string', enum: ['active', 'archived'] },
            createdAt: { type: 'string' },
            updatedAt: { type: 'string' },
          },
        },
        ProjectMember: {
          type: 'object',
          properties: {
            projectId: { type: 'string' },
            userId: { type: 'string' },
            role: { type: 'string', enum: ['owner', 'member'] },
            createdAt: { type: 'string' },
          },
        },
      },
    },
  } as const;
}
