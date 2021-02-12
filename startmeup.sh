npm init
npm i -D typescript@next ts-node nodemon dotenv eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin prettier eslint-config-prettier eslint-plugin-prettier
npx tsc --init
mkdir src dist
echo "const writeMessage = (message: string) => { console.log(message); }; writeMessage('TS app on Node JS');" >> src/app.ts

cat << EOF
Now make the following modifications to tsconfig.
{
 "compilerOptions": {
    //...  
    "target": "ESNEXT", 
    "rootDir": "src",
    "allowJs": true,
    "outDir": "dist", 
    "strict": true,
    "moduleResolution": "node", 
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    // ...
   },
  "include": [
    "./src/**/*"
  ],
  "exclude": [
    "node_modules"
  ]
}

and the following modifications to package.json.

  "scripts": {
    "start-dev": "nodemon --exitcrash --exec ts-node -r dotenv/config src/app.ts",
    "watch-ts": "tsc -w",
    "lint": "eslint 'src/**/*.{js,ts}' --quiet --fix"
  },
EOF

cat > .prettierrc.yml << EOF
tabWidth: 2  
singleQuote: true
EOF

cat > .eslintrc.yaml << EOF
env:  
  node: true  
extends:  
  - plugin:@typescript-eslint/recommended  
  - prettier/@typescript-eslint  
  - plugin:prettier/recommended  
parser: '@typescript-eslint/parser'  
parserOptions:  
  ecmaVersion: 9  
  project: ./tsconfig.json  
plugins:  
 - '@typescript-eslint'
EOF

cat > .gitignore << EOF
# Ignore built ts files
dist/**/*

# API keys and secrets
.env

# Dependency directory
node_modules

# Logs
logs
*.log
npm-debug.log*

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Optional REPL history
.node_repl_history

EOF

git init
git add .
git commit --message "init"
