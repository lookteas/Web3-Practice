import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  // 加载 .env 文件（加载所有变量，不只是 VITE_ 前缀的）
  const env = loadEnv(mode, process.cwd(), '');
  
  return {
    server: {
      port: 8000,
      open: '/index-viem.html'
    },
    build: {
      outDir: 'dist',
      rollupOptions: {
        input: {
          main: './index-viem.html'
        }
      }
    },
    // 将环境变量暴露给客户端
    define: {
      '__SEPOLIA_RPC_URL__': JSON.stringify(env.SEPOLIA_RPC_URL),
      '__PRIVATE_KEY__': JSON.stringify(env.PRIVATE_KEY)
    }
  };
});
