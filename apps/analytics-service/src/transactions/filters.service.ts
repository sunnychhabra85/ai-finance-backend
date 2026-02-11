export class FiltersService {
  build(userId: string, query: any) {
    const where: any = { userId };

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
