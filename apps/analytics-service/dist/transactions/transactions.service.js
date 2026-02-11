"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TransactionsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const rule_engine_1 = require("../categorization/rule-engine");
const memory_service_1 = require("../categorization/memory.service");
const ai_fallback_1 = require("../categorization/ai-fallback");
const pagination_1 = require("./pagination");
const filters_service_1 = require("./filters.service");
const crypto = __importStar(require("crypto"));
let TransactionsService = class TransactionsService {
    prisma;
    memory;
    filters;
    constructor(prisma, memory, filters) {
        this.prisma = prisma;
        this.memory = memory;
        this.filters = filters;
    }
    fingerprint(txn) {
        const str = `${txn.date}-${txn.raw}-${txn.amount}`;
        return crypto.createHash('sha256').update(str).digest('hex');
    }
    async bulkInsert({ userId, transactions }) {
        return this.prisma.$transaction(async (tx) => {
            for (const txn of transactions) {
                const fp = this.fingerprint(txn);
                const result = (0, rule_engine_1.applyRules)(txn.raw) ||
                    (await this.memory.find(txn.raw)) ||
                    (await (0, ai_fallback_1.aiFallback)(txn.raw));
                if (!result)
                    continue;
                await this.memory.save(txn.raw, result);
                await this.prisma.transaction.upsert({
                    where: {
                        userId_fingerprint: {
                            userId,
                            fingerprint: fp,
                        },
                    },
                    update: {
                        ...txn,
                        ...result,
                    },
                    create: {
                        userId,
                        ...txn,
                        ...result,
                        fingerprint: fp,
                    },
                });
            }
            return { status: 'ok' };
        });
    }
    async list(userId, query) {
        const where = this.filters.build(userId, query);
        return this.prisma.transaction.findMany({
            where,
            orderBy: { date: 'desc' },
            ...(0, pagination_1.paginate)(Number(query.page) || 1, Number(query.limit) || 20),
        });
    }
};
exports.TransactionsService = TransactionsService;
exports.TransactionsService = TransactionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        memory_service_1.MemoryService,
        filters_service_1.FiltersService])
], TransactionsService);
//# sourceMappingURL=transactions.service.js.map