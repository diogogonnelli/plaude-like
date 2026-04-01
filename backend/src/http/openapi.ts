export function buildOpenApiDocument(baseUrl: string) {
  return {
    openapi: '3.1.0',
    info: {
      title: 'Plaude Like API',
      version: '1.0.0',
      description: 'API HTTP para ingestao, transcricao, resumo, chat e exportacao de notas de audio.',
    },
    servers: [
      {
        url: baseUrl,
      },
    ],
    tags: [
      { name: 'System', description: 'Healthcheck e metadata da API' },
      { name: 'Recordings', description: 'Operacoes sobre gravacoes e notas' },
      { name: 'Chat', description: 'Perguntas sobre uma nota pronta' },
      { name: 'Export', description: 'Exportacao textual da nota' },
      { name: 'Webhooks', description: 'Callbacks de provedores externos' },
    ],
    paths: {
      '/health': {
        get: {
          tags: ['System'],
          summary: 'Healthcheck do backend',
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
              in: 'header',
              name: 'x-user-id',
              required: false,
              schema: { type: 'string' },
              description: 'Identificador do usuario. Em dev, o padrao e demo-user.',
            },
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
                    sourceType: { type: 'string', enum: ['microphone', 'upload'] },
                    durationMs: { type: 'integer' },
                    audioPath: { type: 'string' },
                  },
                  required: ['title', 'sourceType'],
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
                    sourceType: { type: 'string', enum: ['microphone', 'upload'] },
                    durationMs: { type: 'integer' },
                  },
                  required: ['file', 'title'],
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
    },
    components: {
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
            title: { type: 'string' },
            sourceType: { type: 'string', enum: ['microphone', 'upload'] },
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
      },
    },
  } as const;
}
