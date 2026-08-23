import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/lifecycle/app_lifecycle_cubit.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/app/router/app_router.dart';
import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/deep_links/deep_link_mapper.dart';
import 'package:moment/core/errors/exception_mapper.dart';
import 'package:moment/core/firebase/firebase_bootstrap.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/network/network_client.dart';
import 'package:moment/core/push/push_bridge.dart';
import 'package:moment/core/push/push_registration_service.dart';
import 'package:moment/core/realtime/moment_realtime_subscriber.dart';
import 'package:moment/core/supabase/supabase_bootstrap.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/home_widget_sync_service.dart';
import 'package:moment/features/moments/data/datasources/social_remote_data_source.dart';
import 'package:moment/features/moments/data/repositories/social_repository_impl.dart';
import 'package:moment/features/moments/domain/repositories/social_repository.dart';
import 'package:moment/features/moments/data/datasources/moments_remote_data_source.dart';
import 'package:moment/features/moments/data/repositories/moment_repository_impl.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/cubit/pings_cubit.dart';
import 'package:moment/features/memories/data/datasources/memories_remote_data_source.dart';
import 'package:moment/features/memories/data/repositories/memory_repository_impl.dart';
import 'package:moment/features/memories/domain/repositories/memory_repository.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/prompts/data/datasources/prompts_remote_data_source.dart';
import 'package:moment/features/prompts/data/repositories/prompt_repository_impl.dart';
import 'package:moment/features/prompts/domain/entities/camera_prompt_context.dart';
import 'package:moment/features/prompts/domain/repositories/prompt_repository.dart';
import 'package:moment/features/prompts/presentation/cubit/prompt_cubit.dart';
import 'package:moment/features/time_travel/data/datasources/time_travel_remote_data_source.dart';
import 'package:moment/features/time_travel/data/repositories/time_travel_repository_impl.dart';
import 'package:moment/features/time_travel/domain/repositories/time_travel_repository.dart';
import 'package:moment/features/time_travel/presentation/cubit/time_travel_cubit.dart';
import 'package:moment/features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'package:moment/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:moment/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:moment/features/subscription/presentation/cubit/premium_cubit.dart';
import 'package:moment/features/widget_preferences/data/datasources/widget_preferences_local_cache.dart';
import 'package:moment/features/widget_preferences/data/datasources/widget_preferences_remote_data_source.dart';
import 'package:moment/features/widget_preferences/data/repositories/widget_preferences_repository_impl.dart';
import 'package:moment/features/widget_preferences/domain/repositories/widget_preferences_repository.dart';
import 'package:moment/features/widget_preferences/presentation/cubit/widget_customization_cubit.dart';
import 'package:moment/features/circles/data/circle_image_resolver.dart';
import 'package:moment/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:moment/features/circles/data/repositories/circle_repository_impl.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/circles/presentation/circles_list_refresh.dart';
import 'package:moment/features/circles/presentation/cubit/circle_detail_cubit.dart';
import 'package:moment/features/circles/presentation/cubit/circles_cubit.dart';
import 'package:moment/features/friends/data/datasources/friends_remote_data_source.dart';
import 'package:moment/features/friends/data/repositories/friends_repository_impl.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:moment/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/auth/domain/usecases/auth_usecases.dart';
import 'package:moment/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:moment/features/profile/data/avatar_url_resolver.dart';
import 'package:moment/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:moment/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:moment/features/profile/domain/repositories/profile_repository.dart';
import 'package:moment/features/profile/domain/usecases/profile_usecases.dart';
import 'package:moment/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:moment/features/settings/data/datasources/support_remote_data_source.dart';
import 'package:moment/features/settings/data/repositories/support_repository_impl.dart';
import 'package:moment/features/settings/domain/repositories/support_repository.dart';
import 'package:moment/features/settings/data/datasources/appearance_preferences_local_cache.dart';
import 'package:moment/features/settings/data/datasources/notification_preferences_local_cache.dart';
import 'package:moment/features/settings/presentation/cubit/appearance_cubit.dart';
import 'package:moment/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:moment/features/settings/presentation/cubit/report_problem_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  required AppEnv env,
  required SupabaseBootstrap supabaseBootstrap,
  required FirebaseBootstrap firebaseBootstrap,
  AuthRepository? authRepository,
  ProfileRepository? profileRepository,
  FriendsRepository? friendsRepository,
}) async {
  await sl.reset();

  sl
    ..registerSingleton<AppEnv>(env)
    ..registerSingleton<AppLogger>(const AppLogger())
    ..registerSingleton<ExceptionMapper>(const ExceptionMapper())
    ..registerSingleton<DeepLinkMapper>(const DeepLinkMapper())
    ..registerSingleton<NetworkClient>(const NetworkClient())
    ..registerSingleton<SupabaseBootstrap>(supabaseBootstrap)
    ..registerSingleton<FirebaseBootstrap>(firebaseBootstrap);

  if (authRepository != null) {
    sl.registerSingleton<AuthRepository>(authRepository);
  } else {
    sl
      ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
      ..registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSource(sl(), sl()),
      )
      ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(sl(), sl()),
      )
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl(), sl()),
      );
  }

  if (profileRepository != null) {
    sl.registerSingleton<ProfileRepository>(profileRepository);
  } else if (!sl.isRegistered<ProfileRepository>()) {
    if (!sl.isRegistered<ProfileRemoteDataSource>()) {
      sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
      sl.registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSource(sl(), sl()),
      );
    }
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        sl(),
        () => sl<AuthRepository>().currentUserId,
        sl(),
      ),
    );
  }

  if (!sl.isRegistered<AvatarUrlResolver>()) {
    sl.registerLazySingleton<AvatarUrlResolver>(() => AvatarUrlResolver(sl()));
  }

  if (friendsRepository != null) {
    sl.registerSingleton<FriendsRepository>(friendsRepository);
  } else if (!sl.isRegistered<FriendsRepository>()) {
    if (!sl.isRegistered<SupabaseClient>()) {
      sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
    }
    sl.registerLazySingleton<FriendsRemoteDataSource>(
      () => FriendsRemoteDataSource(sl()),
    );
    sl.registerLazySingleton<FriendsRepository>(
      () =>
          FriendsRepositoryImpl(sl(), () => sl<AuthRepository>().currentUserId),
    );
  }

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }
  sl.registerLazySingleton<MomentsRemoteDataSource>(
    () => MomentsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<MomentRepository>(
    () => MomentRepositoryImpl(sl(), () => sl<AuthRepository>().currentUserId),
  );
  sl.registerLazySingleton<SocialRemoteDataSource>(
    () => SocialRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(sl(), () => sl<AuthRepository>().currentUserId),
  );
  if (!sl.isRegistered<CircleImageResolver>()) {
    sl.registerLazySingleton<CircleImageResolver>(() => CircleImageResolver(sl()));
  }

  sl.registerLazySingleton<CirclesRemoteDataSource>(
    () => CirclesRemoteDataSource(sl(), sl()),
  );
  sl.registerLazySingleton<CircleRepository>(
    () => CircleRepositoryImpl(
      sl(),
      sl(),
      () => sl<AuthRepository>().currentUserId,
    ),
  );
  sl.registerLazySingleton<PromptsRemoteDataSource>(
    () => PromptsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<PromptRepository>(
    () => PromptRepositoryImpl(sl(), () => sl<AuthRepository>().currentUserId),
  );
  sl.registerLazySingleton<MemoriesRemoteDataSource>(
    () => MemoriesRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<MemoryRepository>(
    () => MemoryRepositoryImpl(
      sl(),
      sl(),
      () => sl<AuthRepository>().currentUserId,
    ),
  );
  sl.registerLazySingleton<TimeTravelRemoteDataSource>(
    () => TimeTravelRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<TimeTravelRepository>(
    () => TimeTravelRepositoryImpl(
      sl(),
      sl(),
      () => sl<AuthRepository>().currentUserId,
    ),
  );
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      sl(),
      () => sl<AuthRepository>().currentUserId,
    ),
  );
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(
      sl(),
      () => sl<AuthRepository>().currentUserId,
    ),
  );
  sl.registerLazySingleton<WidgetPreferencesRemoteDataSource>(
    () => WidgetPreferencesRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<WidgetPreferencesRepository>(
    () => WidgetPreferencesRepositoryImpl(
      sl(),
      () => sl<AuthRepository>().currentUserId,
    ),
  );

  sl
    ..registerLazySingleton(AndroidWidgetBridge.new)
    ..registerLazySingleton(WidgetPreferencesLocalCache.new)
    ..registerLazySingleton(NotificationPreferencesLocalCache.new)
    ..registerLazySingleton(AppearancePreferencesLocalCache.new)
    ..registerLazySingleton(PushBridge.new)
    ..registerLazySingleton(
      () => PushRegistrationService(sl(), sl<SupabaseClient>(), sl()),
    )
    ..registerLazySingleton(() => HomeWidgetSyncService(sl(), sl(), sl(), sl(), sl()))
    ..registerLazySingleton(
      () => MomentRealtimeSubscriber(
        sl<SupabaseClient>(),
        () => sl<AuthRepository>().currentUserId,
        sl(),
      ),
    );

  sl
    ..registerLazySingleton(() => LoginUseCase(sl(), sl()))
    ..registerLazySingleton(() => RegisterUseCase(sl(), sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl(), sl()))
    ..registerLazySingleton(() => RestoreSessionUseCase(sl()))
    ..registerLazySingleton(() => ResetPasswordUseCase(sl(), sl()))
    ..registerLazySingleton(() => DeleteAccountUseCase(sl(), sl()))
    ..registerLazySingleton(() => GetCurrentProfileUseCase(sl()))
    ..registerLazySingleton(() => UpdateProfileUseCase(sl()))
    ..registerLazySingleton(() => UploadAvatarUseCase(sl()))
    ..registerLazySingleton(() => CheckUsernameAvailabilityUseCase(sl()))
    ..registerLazySingleton<SessionCubit>(
      () => SessionCubit(authRepository: sl()),
    )
    ..registerFactory(() => LoginCubit(sl(), sl()))
    ..registerFactory(() => RegisterCubit(sl()))
    ..registerFactory(() => ProfileCubit(sl(), sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => AccountCubit(sl(), sl(), sl()))
    ..registerFactory(() => FriendsCubit(sl()))
    ..registerFactoryParam<FriendProfileCubit, String, void>(
      (userId, _) => FriendProfileCubit(sl(), userId),
    )
    ..registerFactory(() => BlockedUsersCubit(sl()))
    ..registerFactory(() => HomeCubit(sl(), sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => PingsCubit(sl(), sl()))
    ..registerFactoryParam<CameraCubit, CameraPromptContext?, void>(
      (promptContext, _) => CameraCubit(
        sl(),
        sl(),
        sl(),
        sl(),
        () => sl<AuthRepository>().currentUserId,
        promptContext: promptContext,
      ),
    )
    ..registerFactory(() => PromptCubit(sl(), sl()))
    ..registerFactoryParam<CircleTodayCubit, String, void>(
      (circleId, _) => CircleTodayCubit(sl(), sl(), sl(), circleId),
    )
    ..registerFactory(() => MemoryVaultCubit(sl(), sl(), sl(), sl()))
    ..registerFactory(() => TimeTravelCubit(sl()))
    ..registerFactory(() => PremiumCubit(sl()))
    ..registerFactory(() => ReportProblemCubit(sl()))
    ..registerFactory(() => NotificationSettingsCubit(sl(), sl()))
    ..registerFactory(
      () => WidgetCustomizationCubit(sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactoryParam<MemoryDetailCubit, String, void>(
      (memoryId, _) => MemoryDetailCubit(sl(), memoryId),
    )
    ..registerFactoryParam<MemoryEditCubit, String, void>(
      (memoryId, _) => MemoryEditCubit(sl(), sl(), memoryId),
    )
    ..registerFactory(() => CreateMemoryCubit(sl(), sl()))
    ..registerFactoryParam<MomentDetailCubit, String, void>(
      (momentId, _) => MomentDetailCubit(sl(), sl(), momentId),
    )
    ..registerLazySingleton(CirclesListRefresh.new)
    ..registerFactory(() => CirclesCubit(sl(), sl()))
    ..registerFactoryParam<CircleDetailCubit, String, void>(
      (circleId, _) => CircleDetailCubit(sl(), sl(), sl(), sl(), circleId),
    )
    ..registerLazySingleton<AppearanceCubit>(
      () => AppearanceCubit(sl())..load(),
    )
    ..registerLazySingleton<AppLifecycleCubit>(AppLifecycleCubit.new)
    ..registerLazySingleton<GoRouter>(
      () => createAppRouter(
        sessionCubit: sl<SessionCubit>(),
        deepLinkMapper: sl<DeepLinkMapper>(),
      ),
    );
}
