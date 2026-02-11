"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UploadController = void 0;
const common_1 = require("@nestjs/common");
const upload_service_1 = require("./upload.service");
let UploadController = class UploadController {
    service;
    constructor(service) {
        this.service = service;
    }
    async uploadFile(req) {
        const file = await req.file();
        if (!file) {
            throw new Error('No file received');
        }
        const buffer = await file.toBuffer();
        const userId = req.headers['x-user-id'];
        return this.service.createUpload(userId, {
            originalname: file.filename,
            size: buffer.length,
            buffer,
        });
    }
    async listUploads(req) {
        const userId = req.headers['x-user-id'];
        return this.service.list(userId);
    }
    async recent(userId) {
        const uploads = await this.service.list(userId);
        return uploads.map((u) => ({
            id: u.id,
            fileName: u.fileName,
            size: this.formatSize(u.fileSize),
            uploadedAt: this.formatDate(u.createdAt),
            status: u.status === 'UPLOADED' ? 'Done' : 'Processing',
        }));
    }
    formatSize(bytes) {
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
    formatDate(date) {
        return new Date(date).toLocaleDateString('en-US', {
            month: 'short',
            day: '2-digit',
        });
    }
};
exports.UploadController = UploadController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UploadController.prototype, "uploadFile", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UploadController.prototype, "listUploads", null);
__decorate([
    (0, common_1.Get)('recent'),
    __param(0, (0, common_1.Query)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UploadController.prototype, "recent", null);
exports.UploadController = UploadController = __decorate([
    (0, common_1.Controller)('upload'),
    __metadata("design:paramtypes", [upload_service_1.UploadService])
], UploadController);
//# sourceMappingURL=upload.controller.js.map