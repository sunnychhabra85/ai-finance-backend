import { Injectable } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class EventPublisher {
  // publishFileUploaded(payload: any) {
  //   // Later: push to SQS / Kafka
  //   console.log('📨 FILE_UPLOADED event:', payload);
  // }
  async publishFileUploaded(payload: any) {
    console.log('📨 FILE_UPLOADED event:', payload);
    await axios.post(
      'http://localhost:3004/internal/file-uploaded',
      payload,
    );
  }

}
