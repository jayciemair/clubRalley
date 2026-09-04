import { customAlphabet } from "nanoid";

const gen = customAlphabet("0123456789abcdefghijklmnopqrstuvwxyz", 10);

export function id(prefix = ""): string {
  return prefix + gen();
}
