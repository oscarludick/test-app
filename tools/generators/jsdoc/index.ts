import { formatFiles, Tree } from '@nrwl/devkit';
import { Configuration, OpenAIApi } from 'openai';

const OPENAI_ORG = 'org-Msn6tFyIJE5NvJ1zbwaDIKzP';
const OPENAI_API_KEY = '';

const template = `
/**
 * A description of the function.
 *
 * @function functionName
 * @param {parameterType} parameterName - Description of the parameter.
 * @returns {returnType} Description of the return value.
 * @throws {errorType} Description of the error that may be thrown.
 * @see {externalFunctionType}
 *
 * @example
 * \`\`\`functionName(parameterValue);\`\`\`
 *
 */
`;

async function generateJsdoc(text: string): Promise<string> {
  const configuration = new Configuration({
    apiKey: OPENAI_API_KEY,
    organization: OPENAI_ORG,
  });
  const openai = new OpenAIApi(configuration);
  const prompt = `Create the jsdoc of this code (use the following template ${template} in those where it applies): \n\n ${text}`;

  const completion = await openai.createCompletion({
    stop: text,
    max_tokens: 2048,
    model: 'text-davinci-003',
    prompt,
  });

  const jsdoc = completion.data.choices[0].text?.trim();

  if (!jsdoc) {
    throw new Error('Failed to generate JSDoc comment.');
  }

  return jsdoc;
}

export default async function (tree: Tree, options: any) {
  const filePath = options.path || '';

  if (!filePath) {
    throw new Error('Path is required.');
  }

  const text = tree.read(filePath);

  if (!text) {
    throw new Error(`File ${filePath} does not exist.`);
  }

  const sourceText = text.toString('utf-8');
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

  let newSourceText = sourceText;

  for (const fn in functions) {
    const func = functions[fn];
    const newJSDocComment = await generateJsdoc(func.body);
    const existingJSDocComment =
      newSourceText.slice(0, func.body.indexOf('{')).match(/\/\*\*[\s\S]*?\*\//) || '';
    const newFunctionBody = `${existingJSDocComment}\n${newJSDocComment}\n${func.body}`;
    newSourceText = newSourceText.replace(func.body, newFunctionBody);
  }

  tree.write(filePath, newSourceText);

  await formatFiles(tree);
  return () => {};
}
