"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.paginate = void 0;
const paginate = (page = 1, limit = 20) => ({
    skip: (page - 1) * limit,
    take: limit,
});
exports.paginate = paginate;
//# sourceMappingURL=pagination.js.map