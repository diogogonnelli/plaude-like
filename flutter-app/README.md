# GravAcao Flutter App

Cliente Flutter do GravAcao, com co-branding SPOT, para Android, iOS e Web.

## Getting Started

```bash
flutter pub get
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8787
```

Para autenticar contra Supabase no app Web, adicione tambem:

```bash
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8787 --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co --dart-define=SUPABASE_ANON_KEY=sua_supabase_anon_key
```

Para mais contexto operacional, consulte o `README.md` da raiz.

## Exportar iOS no Mac

O projeto ja usa o bundle identifier `com.spotpromo.gravacao` para o app iOS.

Checklist:

1. Abra `app/ios/Runner.xcworkspace` no Xcode.
2. Em `Runner > Signing & Capabilities`, selecione o seu `Team`.
3. Confirme que o `Bundle Identifier` esta como `com.spotpromo.gravacao`.
4. Confira a versao em `pubspec.yaml` e, se necessario, ajuste `version`.
5. Conecte um iPhone ou selecione `Any iOS Device`.
6. Gere o build com:

```bash
flutter clean
flutter pub get
flutter build ipa --release
```

7. Se preferir exportar pelo Xcode, use `Product > Archive` e envie para `TestFlight` ou `App Store Connect`.

Saida esperada do Flutter:

```text
app/build/ios/ipa/
```

Observacoes:

- a assinatura Apple continua sendo obrigatoria no Mac que executa o build
- o app ja declara permissao de microfone e modo de audio em background no target iOS
