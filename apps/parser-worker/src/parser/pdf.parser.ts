const pdfjsLib = require('pdfjs-dist/legacy/build/pdf.js');

export const extractRawTransactions = async (buffer: Buffer) => {
  const uint8Array = new Uint8Array(buffer);
  const pdf = await pdfjsLib.getDocument({ data: uint8Array }).promise;

  let tokens: string[] = [];

  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const content = await page.getTextContent();

    content.items.forEach((item: any) => {
      tokens.push(item.str.trim());
    });
  }

  const txns: any[] = [];

  const dateRegex = /^\d{2}-\d{2}-\d{4}$/;
  const amountRegex = /^\d+\.\d{2}$/;

  let i = 0;

  while (i < tokens.length) {
    if (dateRegex.test(tokens[i])) {
      const date = tokens[i];

      // skip value date (next token)
      i += 2;

      let rawParts: string[] = [];

      // collect text until we hit amount
      while (i < tokens.length && !amountRegex.test(tokens[i])) {
        rawParts.push(tokens[i]);
        i++;
      }

      const amount = parseFloat(tokens[i] || '0');

      const raw = rawParts.join(' ').replace(/\s+/g, ' ').trim();

      if (raw.length > 5 && amount > 0) {
        txns.push({
          date,
          raw_particular: raw,
          amount,
        });
      }
    }

    i++;
  }

  return txns;
};
