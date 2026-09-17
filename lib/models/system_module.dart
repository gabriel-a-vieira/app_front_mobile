/// Mirrors the backend's SystemModule enum (com.softix.app_back.permission).
/// Adding a module there means adding the matching constant here too, so the
/// permission matrix screen and the gating checks can reference it.
enum SystemModule {
  client,
  professional,
  serviceOffering,
  availability,
  product,
  user,
  appointment;

  String get apiValue {
    switch (this) {
      case SystemModule.client:
        return 'CLIENT';
      case SystemModule.professional:
        return 'PROFESSIONAL';
      case SystemModule.serviceOffering:
        return 'SERVICE_OFFERING';
      case SystemModule.availability:
        return 'AVAILABILITY';
      case SystemModule.product:
        return 'PRODUCT';
      case SystemModule.user:
        return 'USER';
      case SystemModule.appointment:
        return 'APPOINTMENT';
    }
  }

  String get label {
    switch (this) {
      case SystemModule.client:
        return 'Clientes';
      case SystemModule.professional:
        return 'Profissionais';
      case SystemModule.serviceOffering:
        return 'Servicos';
      case SystemModule.availability:
        return 'Disponibilidade';
      case SystemModule.product:
        return 'Produtos';
      case SystemModule.user:
        return 'Usuarios';
      case SystemModule.appointment:
        return 'Agendamentos';
    }
  }

  static SystemModule? fromApiValue(String value) {
    for (final module in SystemModule.values) {
      if (module.apiValue == value) {
        return module;
      }
    }

    return null;
  }
}

/// Mirrors the backend's CrudAction enum.
enum CrudAction { create, update, list, delete }
