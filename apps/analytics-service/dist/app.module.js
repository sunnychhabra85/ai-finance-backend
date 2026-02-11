"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("./prisma/prisma.service");
const transactions_controller_1 = require("./transactions/transactions.controller");
const transactions_service_1 = require("./transactions/transactions.service");
const filters_service_1 = require("./transactions/filters.service");
const monthly_service_1 = require("./aggregates/monthly.service");
const category_service_1 = require("./aggregates/category.service");
const memory_service_1 = require("./categorization/memory.service");
const aggregates_controller_1 = require("./aggregates/aggregates.controller");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        controllers: [transactions_controller_1.TransactionsController, aggregates_controller_1.AggregatesController],
        providers: [
            prisma_service_1.PrismaService,
            transactions_service_1.TransactionsService,
            filters_service_1.FiltersService,
            monthly_service_1.MonthlyService,
            category_service_1.CategoryService,
            memory_service_1.MemoryService,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map