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
exports.AggregatesController = void 0;
const common_1 = require("@nestjs/common");
const monthly_service_1 = require("./monthly.service");
const category_service_1 = require("./category.service");
const swagger_1 = require("@nestjs/swagger");
let AggregatesController = class AggregatesController {
    monthly;
    category;
    constructor(monthly, category) {
        this.monthly = monthly;
        this.category = category;
    }
    monthlyAgg(userId) {
        return this.monthly.get(userId);
    }
    categoryAgg(userId) {
        return this.category.get(userId);
    }
};
exports.AggregatesController = AggregatesController;
__decorate([
    (0, common_1.Get)('monthly'),
    (0, swagger_1.ApiQuery)({ name: 'userId', required: true }),
    __param(0, (0, common_1.Query)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], AggregatesController.prototype, "monthlyAgg", null);
__decorate([
    (0, common_1.Get)('category'),
    (0, swagger_1.ApiQuery)({ name: 'userId', required: true }),
    __param(0, (0, common_1.Query)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], AggregatesController.prototype, "categoryAgg", null);
exports.AggregatesController = AggregatesController = __decorate([
    (0, swagger_1.ApiTags)('Aggregates'),
    (0, common_1.Controller)('aggregates'),
    __metadata("design:paramtypes", [monthly_service_1.MonthlyService,
        category_service_1.CategoryService])
], AggregatesController);
//# sourceMappingURL=aggregates.controller.js.map