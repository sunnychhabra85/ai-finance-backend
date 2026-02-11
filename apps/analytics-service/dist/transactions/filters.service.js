"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FiltersService = void 0;
class FiltersService {
    build(userId, query) {
        const where = { userId };
        if (query.category) {
            where.category = query.category;
        }
        if (query.type) {
            where.type = query.type;
        }
        if (query.search) {
            where.raw = {
                contains: query.search,
                mode: 'insensitive',
            };
        }
        if (query.from && query.to) {
            where.date = {
                gte: query.from,
                lte: query.to,
            };
        }
        return where;
    }
}
exports.FiltersService = FiltersService;
//# sourceMappingURL=filters.service.js.map