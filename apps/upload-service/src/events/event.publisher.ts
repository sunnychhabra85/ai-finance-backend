import { Injectable } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class EventPublisher {
  private readonly analyticsServiceUrl: string;

  constructor() {
    this.analyticsServiceUrl = process.env.ANALYTICS_SERVICE_URL || 'http://localhost:3004';
  }

  async publishFileUploaded(payload: any) {
    const url = `${this.analyticsServiceUrl}/internal/file-uploaded`;
    console.log('📨 FILE_UPLOADED event:', payload);
    console.log('📤 Sending to:', url);
    
    try {
      await axios.post(url, payload);
      console.log('✅ Successfully notified analytics service');
    } catch (error) {
      console.error('❌ Failed to notify analytics service:', error.message);
      throw error;
    }
  }

}
