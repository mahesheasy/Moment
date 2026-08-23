# Architecture

Moment uses feature-first Clean Architecture with `flutter_bloc` and `go_router`.

```
lib/
  app/          bootstrap, DI, router, lifecycle, foundation shell
  core/         config, errors, logging, result, theme shell, supabase/firebase bootstrap
  features/     auth, profile, friends, circles, moments, memories, notifications, settings
```

Each feature:

```
feature/
  domain/         entities, repository contracts, use cases
  data/           models, data sources, repository implementations
  presentation/   cubits/blocs, pages, widgets
```

Flow:

```
Page → Cubit/Bloc → UseCase → Repository → DataSource → Supabase
```

## Dependencies

Allowed in Version 0.1:

- `flutter_bloc`
- `go_router`
- `get_it`
- `equatable`
- `supabase_flutter`

Firebase packages are deferred until Version 0.7 so Android/iOS builds stay valid without `google-services` files.

## Security

- Publishable key only on the client
- Service-role keys are rejected by `AppEnv.validate()`
- Logger redacts token/key/secret fields
- Product tables and RLS start in Version 0.3
