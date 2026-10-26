// Compatibility entry point for npm-based workspaces. All UI/build work is real Flutter.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
const win=process.platform==='win32';
const filename=win?'flutter.bat':'flutter';
const candidates=[
  process.env.FLUTTER_ROOT && path.join(process.env.FLUTTER_ROOT,'bin',filename),
  path.join(os.homedir(),'.codex','toolchains','flutter','bin',filename),
  ...(process.env.PATH||'').split(path.delimiter).map(p=>path.join(p,filename)),
].filter(Boolean);
const flutter=candidates.find(p=>fs.existsSync(p));
if(!flutter) {console.error('Flutter SDK not found. Install Flutter and set FLUTTER_ROOT or PATH. See README.md.');process.exit(1);}
const mode=process.argv[2];
const cloud=fs.existsSync('.env.supabase.json')?['--dart-define-from-file=.env.supabase.json']:[];
const args=mode==='dev'?['run','-d','web-server','--web-hostname=127.0.0.1','--web-port=3000',...cloud]:
  mode==='build'?['build','web','--release','--no-web-resources-cdn',...cloud]:mode==='analyze'?['analyze']:mode==='test'?['test']:null;
if(!args) {console.error('Expected dev, build, analyze or test');process.exit(1);}
const env={...process.env};
if(win) env.PATH=[path.dirname(flutter),path.join(env.SystemRoot||'C:\\Windows','System32'),env.SystemRoot||'C:\\Windows',env.PATH].join(';');
const result=win?spawnSync(path.join(env.SystemRoot||'C:\\Windows','System32','cmd.exe'),['/d','/s','/c',`flutter.bat ${args.join(' ')}`],{stdio:'inherit',env}):
  spawnSync(flutter,args,{stdio:'inherit',env});
process.exit(result.status??1);
