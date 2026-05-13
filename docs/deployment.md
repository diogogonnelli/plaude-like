# Deploy

O deploy oficial esta documentado em [`../DEPLOY.md`](../DEPLOY.md).

Contrato atual:

- nginx aponta para `public/index.php`;
- assets estaticos ficam em `public/build` no disco;
- assets sao acessados por `/build/...`;
- nao use `PUBLIC_PREFIX`.

Validacao local minima:

```powershell
composer test
npm run build
php artisan serve
```

Endpoints esperados:

- `/`
- `/login`
- `/admin`
- `/api/health`
- `/build/manifest.json`
