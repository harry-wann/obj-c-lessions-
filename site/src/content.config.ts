import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const term = z.object({ en: z.string(), tw: z.string(), cn: z.string().optional(), jp: z.string().optional() });

const lessons = defineCollection({
  loader: glob({ pattern: '**/*.mdx', base: './src/content/lessons' }),
  schema: z.object({
    title: z.string(),
    module: z.number(),            // 0..12
    chapter: z.string(),           // "2.4"
    order: z.number(),             // sort key inside module, e.g. 4
    minutes: z.number().default(20),
    prereq: z.array(z.string()).default([]),   // ["2.3"]
    objectives: z.array(z.string()).default([]),
    summary: z.string().default(''),
    optional: z.boolean().default(false),       // 選讀
    terms: z.array(term).default([]),
    appProgress: z.string().optional(),        // 📱 小帳本進度
    draft: z.boolean().default(false),
  }),
});

const exerciseBase = {
  id: z.string(),
  chapter: z.string(),
  type: z.enum(['quiz', 'fill', 'parsons', 'predict', 'spot', 'crash', 'code', 'xcode', 'flash']),
  title: z.string(),
  mobile: z.boolean().default(true),
  minutes: z.number().default(3),
  prompt: z.string().default(''),
  hints: z.array(z.string()).default([]),
  solution_note: z.string().default(''),
  tier: z.enum(['basic', 'advanced', 'interview']).default('basic'),
};

const exercises = defineCollection({
  loader: glob({ pattern: '**/*.yaml', base: './src/content/exercises' }),
  schema: z.object({ ...exerciseBase }).passthrough(),
});

const modules = defineCollection({
  loader: glob({ pattern: '*.yaml', base: './src/content/modules' }),
  schema: z.object({
    number: z.number(),
    title: z.string(),
    days: z.string(),
    blurb: z.string(),
    milestone: z.string().default(''),
  }),
});

export const collections = { lessons, exercises, modules };
