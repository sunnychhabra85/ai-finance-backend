import { parse } from 'csv-parse/sync';

export const parseCSV = (buffer: Buffer) => {
  const records = parse(buffer, {
    columns: true,
    skip_empty_lines: true,
  });

  return records.map((r: any) => ({
    date: r.Date,
    description: r.Description,
    amount: parseFloat(r.Amount),
  }));
};
