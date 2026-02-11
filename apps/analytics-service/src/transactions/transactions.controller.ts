import { Controller, Post, Body, Get, Query } from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { ApiTags, ApiQuery, ApiBody } from '@nestjs/swagger';

@ApiTags('Transactions')
@Controller('transactions')
export class TransactionsController {
  constructor(private service: TransactionsService) {}

  @Post('bulk')
  @ApiBody({ description: 'Bulk raw transactions from parser-worker' })
  bulk(@Body() body: any) {
    return this.service.bulkInsert(body);
  }

  @Get()
  @ApiQuery({ name: 'userId', required: true })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'type', required: false })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  list(@Query('userId') userId: string, @Query() q: any) {
    return this.service.list(userId, q);
  }
}
