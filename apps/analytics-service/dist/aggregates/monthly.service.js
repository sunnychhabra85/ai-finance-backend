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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MonthlyService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let MonthlyService = class MonthlyService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async get(userId) {
        const txns = await this.prisma.transaction.findMany({
            where: { userId, type: 'MERCHANT' },
        });
        const map = {};
        txns.forEach((t) => {
            const month = t.date.slice(3, 10);
            map[month] = (map[month] || 0) + t.amount;
        });
        return map;
    }
};
exports.MonthlyService = MonthlyService;
exports.MonthlyService = MonthlyService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MonthlyService);
//# sourceMappingURL=monthly.service.js.map