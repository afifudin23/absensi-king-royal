// ─── Gender ───────────────────────────────────────────────────────────────────

const genderOptions = ['Laki-laki', 'Perempuan', 'Lainnya'];

String genderToDisplay(String? api) {
  switch (api) {
    case 'male':
      return 'Laki-laki';
    case 'female':
      return 'Perempuan';
    case 'other':
      return 'Lainnya';
    default:
      return api ?? '-';
  }
}

String genderToApi(String display) {
  switch (display) {
    case 'Laki-laki':
      return 'male';
    case 'Perempuan':
      return 'female';
    default:
      return 'other';
  }
}

// ─── Role ─────────────────────────────────────────────────────────────────────

String roleToDisplay(String? api) {
  switch (api) {
    case 'admin':
      return 'Admin';
    case 'user':
      return 'User';
    default:
      return api ?? '-';
  }
}

// ─── Employment Status ────────────────────────────────────────────────────────

const employmentStatusOptions = ['Tetap', 'Kontrak', 'Magang', 'Freelance'];

String employmentStatusToDisplay(String? api) {
  switch (api) {
    case 'permanent':
      return 'Tetap';
    case 'contract':
      return 'Kontrak';
    case 'internship':
      return 'Magang';
    case 'freelance':
      return 'Freelance';
    default:
      return api ?? '-';
  }
}

String employmentStatusToApi(String display) {
  switch (display) {
    case 'Tetap':
      return 'permanent';
    case 'Kontrak':
      return 'contract';
    case 'Magang':
      return 'internship';
    case 'Freelance':
      return 'freelance';
    default:
      return 'permanent';
  }
}

// ─── Leave Type ───────────────────────────────────────────────────────────────

String leaveTypeToApi(String display) {
  switch (display) {
    case 'Sakit':
      return 'sick';
    case 'Cuti':
      return 'leave';
    case 'Extra Off':
      return 'extra_off';
    case 'Lembur':
      return 'overtime';
    default:
      return 'sick';
  }
}

// ─── Attendance Status ────────────────────────────────────────────────────────

String attendanceStatusToDisplay(String? api) {
  switch (api) {
    case 'present':
      return 'Hadir';
    case 'off':
      return 'Off';
    case 'leave':
      return 'Cuti';
    case 'sick':
      return 'Sakit';
    case 'absent':
      return 'Alfa';
    case 'extra_off':
      return 'Extra Off';
    default:
      return api ?? '-';
  }
}
