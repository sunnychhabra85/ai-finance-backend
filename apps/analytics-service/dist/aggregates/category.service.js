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
exports.CategoryService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let CategoryService = class CategoryService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async get(userId) {
        const txns = await this.prisma.transaction.findMany({
            where: { userId },
        });
        let totalDebit = 0;
        let totalCredit = 0;
        const debitByCategory = {};
        const creditByCategory = {};
        txns.forEach((t) => {
            if (t.type === 'INCOME') {
                totalCredit += t.amount;
                creditByCategory[t.category] =
                    (creditByCategory[t.category] || 0) + t.amount;
            }
            else {
                totalDebit += t.amount;
                debitByCategory[t.category] =
                    (debitByCategory[t.category] || 0) + t.amount;
            }
        });
        return {
            totalDebit,
            totalCredit,
            debitByCategory,
            creditByCategory,
        };
    }
};
exports.CategoryService = CategoryService;
exports.CategoryService = CategoryService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CategoryService);
//# sourceMappingURL=category.service.js.map