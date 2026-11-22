'use strict';

document.querySelectorAll('[data-table-filter]').forEach((input) => {
  input.addEventListener('input', () => {
    const group = input.dataset.tableFilter;
    const term = input.value.trim().toLocaleLowerCase('es');
    document.querySelectorAll(`[data-search-row="${group}"]`).forEach((row) => {
      row.hidden = !row.textContent.toLocaleLowerCase('es').includes(term);
    });
  });
});

document.querySelectorAll('form[data-confirm]').forEach((form) => {
  form.addEventListener('submit', (event) => {
    if (!window.confirm(form.dataset.confirm)) event.preventDefault();
  });
});

const careerSelects = document.querySelectorAll('[data-career-select]');
careerSelects.forEach((careerSelect) => {
  const form = careerSelect.form;
  const updateCareerChoices = () => {
    const careerId = careerSelect.value;
    const teacherSelect = form.querySelector('select[name="teacher_id"]');
    if (teacherSelect) {
      let visibleSelectedTeacher = false;
      Array.from(teacherSelect.options).forEach((option, index) => {
        if (index === 0) return;
        const allowed = option.dataset.careerId === careerId;
        option.hidden = !allowed;
        option.disabled = !allowed;
        if (option.selected && allowed) visibleSelectedTeacher = true;
        if (option.selected && !allowed) option.selected = false;
      });
      if (!visibleSelectedTeacher) teacherSelect.value = '';
    }
    form.querySelectorAll('[data-course-career]').forEach((label) => {
      const allowed = label.dataset.courseCareer === careerId;
      label.hidden = !allowed;
      if (!allowed) {
        const checkbox = label.querySelector('input[type="checkbox"]');
        if (checkbox) checkbox.checked = false;
      }
    });
  };
  careerSelect.addEventListener('change', updateCareerChoices);
  updateCareerChoices();
});

document.querySelectorAll('select[name="role"]').forEach((roleSelect) => {
  const form = roleSelect.form;
  const updateRoleFields = () => {
    const requiresCareer = ['career_coordinator', 'teacher', 'student'].includes(roleSelect.value);
    const career = form.querySelector('select[name="career_id"]');
    if (career) career.required = requiresCareer;
    const studentCode = form.querySelector('input[name="student_code"]');
    if (studentCode) studentCode.required = roleSelect.value === 'student';
  };
  roleSelect.addEventListener('change', updateRoleFields);
  updateRoleFields();
});

const mobileNavToggle = document.querySelector('#mobileNavToggle');
const sidebar = document.querySelector('.sidebar');
const closeMobileNav = () => {
  sidebar?.classList.remove('open');
  document.querySelector('.sidebar-backdrop')?.remove();
  document.body.classList.remove('nav-open');
  mobileNavToggle?.setAttribute('aria-expanded', 'false');
  mobileNavToggle?.setAttribute('aria-label', 'Abrir navegación');
};

mobileNavToggle?.addEventListener('click', () => {
  if (!sidebar) return;
  const isOpen = sidebar.classList.toggle('open');
  mobileNavToggle.setAttribute('aria-expanded', String(isOpen));
  mobileNavToggle.setAttribute('aria-label', isOpen ? 'Cerrar navegación' : 'Abrir navegación');
  document.body.classList.toggle('nav-open', isOpen);
  document.querySelector('.sidebar-backdrop')?.remove();
  if (isOpen) {
    const backdrop = document.createElement('button');
    backdrop.type = 'button';
    backdrop.className = 'sidebar-backdrop';
    backdrop.setAttribute('aria-label', 'Cerrar navegación');
    backdrop.addEventListener('click', closeMobileNav);
    document.body.append(backdrop);
    sidebar.querySelector('.nav-link')?.focus();
  }
});

document.querySelectorAll('.sidebar .nav-link').forEach((link) => {
  link.addEventListener('click', closeMobileNav);
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && sidebar?.classList.contains('open')) {
    closeMobileNav();
    mobileNavToggle?.focus();
  }
});
