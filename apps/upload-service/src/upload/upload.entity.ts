export interface UploadEntity {
  id: string;
  fileName: string;
  status: 'UPLOADED' | 'PROCESSING' | 'DONE' | 'FAILED';
}
