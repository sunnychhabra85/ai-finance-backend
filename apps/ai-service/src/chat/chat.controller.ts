import { Controller, Post, Body } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private chat: ChatService) {}

  @Post()
  ask(@Body() body: any) {
    return this.chat.ask(body.userId, body.question);
  }
}
