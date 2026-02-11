import { Controller, Get, Query } from '@nestjs/common';
import { MonthlyService } from './monthly.service';
import { CategoryService } from './category.service';
import { ApiTags, ApiQuery } from '@nestjs/swagger';

@ApiTags('Aggregates')
@Controller('aggregates')
export class AggregatesController {
  constructor(
    private monthly: MonthlyService,
    private category: CategoryService,
  ) {}

  @Get('monthly')
  @ApiQuery({ name: 'userId', required: true })
  monthlyAgg(@Query('userId') userId: string) {
    return this.monthly.get(userId);
  }

  @Get('category')
  @ApiQuery({ name: 'userId', required: true })
  categoryAgg(@Query('userId') userId: string) {
    return this.category.get(userId);
  }
}
