import { formatFiles, Tree } from '@nrwl/devkit';
import { Configuration, OpenAIApi } from 'openai';

const OPENAI_ORG = 'org-Msn6tFyIJE5NvJ1zbwaDIKzP';
const OPENAI_API_KEY = '';

const template = `
it('descriptionTest', () => {
  {assertions}
});
`;

async function generateUnitTest(text: string): Promise<string> {
  const configuration = new Configuration({
    apiKey: OPENAI_API_KEY,
    organization: OPENAI_ORG,
  });
  const openai = new OpenAIApi(configuration);
  const prompt = `Create the unit test of this code (using the template ${template}) with jest: \n\n ${text}`;

  const completion = await openai.createCompletion({
    stop: text,
    max_tokens: 2048,
    model: 'text-davinci-003',
    prompt,
  });

  const unitTest = completion.data.choices[0].text?.trim();

  if (!unitTest) {
    throw new Error('Failed to generate UnitTest');
  }

  return unitTest;
}

export default async function (tree: Tree, options: any) {
  const filePath = options.path || '';
  const filePathTest = filePath.replace('.ts', '.spec.ts');

  if (!filePath) {
    throw new Error('Path is required.');
  }

  const text = tree.read(filePath);
  const textTest = tree.read(filePathTest);

  if (!text) {
    throw new Error(`File ${filePath} does not exist.`);
  }

  if (!textTest) {
    throw new Error(`File ${filePathTest} does not exist.`);
  }

  const sourceText = text.toString('utf-8');
  const sourceTextTest = textTest.toString('utf-8');
  const functionRegex =
    /(private\s+)?(protected\s+)?(public\s+)?\w+\(.*?\)\s*(:\s*\w+)?\s*{\s*[\s\S]*?}/g;

  let match: RegExpExecArray | null;
  let functions: { name: string; body: string }[] = [];

  while ((match = functionRegex.exec(sourceText))) {
    const [fullMatch] = match;
    const nameMatch = fullMatch.match(/\b(\w+)\(/);
    const name = nameMatch ? nameMatch[1] : '';
    const body = fullMatch;
    functions.push({ name, body });
  }

  if (functions.length === 0) {
    throw new Error('No functions found.');
  }

  let newSourceText = sourceTextTest;

  for (const fn in functions) {
    const func = functions[fn];
    const unitTest = await generateUnitTest(func.body);
    newSourceText = newSourceText.replace(`\n});`, `\n\n${unitTest}\n\n});`);
    tree.write(filePathTest, newSourceText);
    await formatFiles(tree);
  }

  //await formatFiles(tree);
  return () => {};
}
