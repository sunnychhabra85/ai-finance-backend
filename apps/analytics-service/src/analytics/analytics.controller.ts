import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';  // ✅ Correct path

@Controller('api/analytics')
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('health')
  health() {
    return { 
      status: 'ok', 
      service: 'analytics-service',
      timestamp: new Date().toISOString()
    };
  }

  @Get('summary')
  @UseGuards(JwtAuthGuard)
  async getSummary(@Request() req: any) {
    return this.analyticsService.getSummary(req.user.id);
  }

  @Get('spending-by-category')
  @UseGuards(JwtAuthGuard)
  async getByCategory(@Request() req: any) {
    return this.analyticsService.getByCategory(req.user.id);
  }

  @Get('top-categories')
  @UseGuards(JwtAuthGuard)
  async getTopCategories(
    @Request() req: any,
    @Query('limit') limit: string = '5',
  ) {
    return this.analyticsService.getTopCategories(req.user.id, parseInt(limit));
  }

  @Get('trends')
  @UseGuards(JwtAuthGuard)
  async getTrends(
    @Request() req: any,
    @Query('period') period: 'daily' | 'weekly' | 'monthly' = 'monthly',
  ) {
    return this.analyticsService.getTrends(req.user.id, period);
  }
}