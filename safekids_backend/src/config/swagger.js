const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API SafeKids Backend',
      version: '1.0.0',
      description: 'Tài liệu API cho SafeKids - Ứng dụng Bảo vệ Trẻ em và Kiểm soát Phụ huynh',
      contact: {
        name: 'Đội ngũ SafeKids',
        email: 'support@safekids.app'
      }
    },
    servers: [
      {
        url: process.env.BACKEND_URL || 'http://localhost:3000',
        description: 'Backend Server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT token from login endpoint'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'User ID' },
            name: { type: 'string', description: 'User name' },
            username: { type: 'string', description: 'Username' },
            fullName: { type: 'string', description: 'Full name' },
            email: { type: 'string', format: 'email', description: 'Email address' },
            phone: { type: 'string', description: 'Phone number' },
            role: { type: 'string', enum: ['parent', 'child'], description: 'User role' },
            age: { type: 'integer', description: 'Age (for child accounts)' },
            avatar: { type: 'string', description: 'Avatar URL' },
            isEmailVerified: { type: 'boolean' },
            isActive: { type: 'boolean' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },
        Error: {
          type: 'object',
          properties: {
            message: { type: 'string' },
            error: { type: 'string' }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: [
    './src/routes/*.js',
    './src/controllers/*.js'
  ]
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
