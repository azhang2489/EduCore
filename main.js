const starterCourses = [
  { id: 'EDU-101', name: 'Diseño de interfaces', category: 'Diseño', teacher: 'Andrea López', enrolled: 18, capacity: 25, status: 'Activo', icon: 'bi-bezier2', tone: 'icon-mint' },
  { id: 'EDU-102', name: 'Base de datos II', category: 'Tecnología', teacher: 'Carlos Méndez', enrolled: 32, capacity: 35, status: 'Activo', icon: 'bi-database-fill', tone: 'icon-lilac' },
  { id: 'EDU-103', name: 'Matemática aplicada', category: 'Ciencias', teacher: 'Julio Rivera', enrolled: 24, capacity: 30, status: 'Activo', icon: 'bi-calculator-fill', tone: 'icon-peach' },
  { id: 'EDU-104', name: 'Programación web', category: 'Tecnología', teacher: 'Ana Castillo', enrolled: 28, capacity: 32, status: 'Activo', icon: 'bi-code-slash', tone: 'icon-blue' },
  { id: 'EDU-105', name: 'Arquitectura de software', category: 'Tecnología', teacher: 'Ricardo Gómez', enrolled: 20, capacity: 28, status: 'Activo', icon: 'bi-diagram-3-fill', tone: 'icon-mint' },
  { id: 'EDU-106', name: 'Comunicación profesional', category: 'Humanidades', teacher: 'Laura Pérez', enrolled: 19, capacity: 25, status: 'Activo', icon: 'bi-chat-square-text-fill', tone: 'icon-lilac' },
  { id: 'EDU-107', name: 'Gestión de proyectos', category: 'Negocios', teacher: 'Miguel Torres', enrolled: 21, capacity: 30, status: 'Activo', icon: 'bi-kanban-fill', tone: 'icon-peach' },
  { id: 'EDU-108', name: 'Fundamentos de redes', category: 'Tecnología', teacher: 'Sofía Díaz', enrolled: 0, capacity: 30, status: 'Borrador', icon: 'bi-router-fill', tone: 'icon-blue' }
];

const students = [
  { initials: 'JR', name: 'Javier Rodríguez', email: 'javier.rodriguez@educore.edu', career: 'Ingeniería de software', courses: 5, attendance: 96, tone: 'avatar-orange' },
  { initials: 'AL', name: 'Ana Lucía Morales', email: 'ana.morales@educore.edu', career: 'Diseño gráfico', courses: 4, attendance: 91, tone: 'avatar-teal' },
  { initials: 'DP', name: 'Daniela Pérez', email: 'daniela.perez@educore.edu', career: 'Ingeniería de sistemas', courses: 6, attendance: 98, tone: 'avatar-purple' },
  { initials: 'CM', name: 'Carlos Mendoza', email: 'carlos.mendoza@educore.edu', career: 'Ciencias computacionales', courses: 5, attendance: 88, tone: 'avatar-teal' },
  { initials: 'SV', name: 'Sofía Vargas', email: 'sofia.vargas@educore.edu', career: 'Ingeniería de software', courses: 4, attendance: 93, tone: 'avatar-orange' }
];

const courseTableBody = document.querySelector('#courseTableBody');
const courseDialog = document.querySelector('#courseDialog');
const courseForm = document.querySelector('#courseForm');
const courseSearch = document.querySelector('#courseSearch');
const statusFilter = document.querySelector('#statusFilter');
const toastMessage = document.querySelector('#toastMessage');
let courses = loadCourses();
let toastTimer;
let activeRole = 'admin';

function loadCourses() {
  try {
    const saved = localStorage.getItem('educore-courses');
    if (!saved) return [...starterCourses];
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? parsed : [...starterCourses];
  } catch {
    return [...starterCourses];
  }
}

function saveCourses() {
  try {
    localStorage.setItem('educore-courses', JSON.stringify(courses));
  } catch {
    showToast('No se pudieron guardar los cambios en este navegador.');
  }
}

function makeElement(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
}

function makeIcon(className) {
  const icon = document.createElement('i');
  icon.className = `bi ${className}`;
  icon.setAttribute('aria-hidden', 'true');
  return icon;
}

function renderCourses() {
  if (!courseTableBody) return;
  const query = (courseSearch?.value || '').trim().toLocaleLowerCase('es');
  const chosenStatus = statusFilter?.value || 'all';
  const visibleCourses = courses.filter((course) => {
    const matchesText = [course.name, course.category, course.teacher, course.id]
      .some((value) => String(value).toLocaleLowerCase('es').includes(query));
    return matchesText && (chosenStatus === 'all' || course.status === chosenStatus);
  });

  const rows = visibleCourses.map((course) => {
    const row = document.createElement('tr');
    const nameCell = document.createElement('td');
    const nameWrap = makeElement('div', 'course-name-cell');
    const art = makeElement('span', `course-mini-art ${course.tone || 'icon-mint'}`);
    art.append(makeIcon(course.icon || 'bi-journal-bookmark-fill'));
    const copy = makeElement('span', 'course-cell-copy');
    copy.append(makeElement('strong', '', course.name), makeElement('small', '', `${course.category} · ${course.id}`));
    nameWrap.append(art, copy);
    nameCell.append(nameWrap);

    const teacherCell = makeElement('td', '', course.teacher);
    const enrollmentCell = document.createElement('td');
    const enrollmentWrap = makeElement('div', 'enrollment-cell');
    enrollmentWrap.append(makeElement('span', '', `${course.enrolled} / ${course.capacity}`));
    const track = makeElement('i');
    const fill = document.createElement('b');
    fill.style.width = `${Math.min(100, Math.round((course.enrolled / Math.max(1, course.capacity)) * 100))}%`;
    track.append(fill);
    enrollmentWrap.append(track);
    enrollmentCell.append(enrollmentWrap);

    const statusCell = document.createElement('td');
    const status = makeElement('span', `status-pill ${course.status === 'Activo' ? 'status-active' : 'status-draft'}`);
    status.append(makeElement('i'), document.createTextNode(course.status));
    statusCell.append(status);

    const actionCell = document.createElement('td');
    const actions = makeElement('div', 'row-actions');
    actions.classList.toggle('d-none', activeRole === 'student');
    const editButton = document.createElement('button');
    editButton.type = 'button';
    editButton.setAttribute('aria-label', `Editar ${course.name}`);
    editButton.title = 'Editar curso';
    editButton.append(makeIcon('bi-pencil'));
    editButton.addEventListener('click', () => openCourseDialog(course.id));
    const deleteButton = document.createElement('button');
    deleteButton.type = 'button';
    deleteButton.className = 'delete-action';
    deleteButton.setAttribute('aria-label', `Eliminar ${course.name}`);
    deleteButton.title = 'Eliminar curso';
    deleteButton.append(makeIcon('bi-trash3'));
    deleteButton.addEventListener('click', () => deleteCourse(course.id));
    actions.append(editButton, deleteButton);
    actionCell.append(actions);
    row.append(nameCell, teacherCell, enrollmentCell, statusCell, actionCell);
    return row;
  });

  courseTableBody.replaceChildren(...rows);
  document.querySelector('#emptyCourses')?.classList.toggle('d-none', visibleCourses.length !== 0);
  const countText = `${visibleCourses.length} ${visibleCourses.length === 1 ? 'curso' : 'cursos'}`;
  document.querySelector('#courseCount').textContent = countText;
  document.querySelector('#tableSummary').textContent = `Mostrando ${visibleCourses.length} ${visibleCourses.length === 1 ? 'curso' : 'cursos'}`;
  const published = courses.filter((course) => course.status === 'Activo').length;
  document.querySelector('#publishedCount').textContent = String(published).padStart(2, '0');
}

function openCourseDialog(courseId) {
  if (activeRole === 'student') {
    showToast('La vista de estudiante no puede modificar cursos.');
    return;
  }
  courseForm.reset();
  document.querySelector('#courseId').value = '';
  document.querySelector('#courseCapacity').value = '30';
  if (courseId) {
    const course = courses.find((item) => item.id === courseId);
    if (!course) return;
    document.querySelector('#courseDialogTitle').textContent = 'Editar curso';
    document.querySelector('#courseId').value = course.id;
    document.querySelector('#courseName').value = course.name;
    document.querySelector('#courseCategory').value = course.category;
    document.querySelector('#courseTeacher').value = course.teacher;
    document.querySelector('#courseCapacity').value = String(course.capacity);
    document.querySelector('#courseStatus').value = course.status;
    document.querySelector('#saveCourseButton').textContent = 'Guardar cambios';
  } else {
    document.querySelector('#courseDialogTitle').textContent = 'Crear nuevo curso';
    document.querySelector('#saveCourseButton').textContent = 'Guardar curso';
  }
  if (typeof courseDialog.showModal === 'function') courseDialog.showModal();
}

function deleteCourse(courseId) {
  if (activeRole === 'student') {
    showToast('La vista de estudiante no puede modificar cursos.');
    return;
  }
  const course = courses.find((item) => item.id === courseId);
  if (!course || !window.confirm(`¿Eliminar el curso “${course.name}” de la vista de demostración?`)) return;
  courses = courses.filter((item) => item.id !== courseId);
  saveCourses();
  renderCourses();
  showToast('Curso eliminado de la demostración.');
}

function showToast(message) {
  if (!toastMessage) return;
  document.querySelector('#toastText').textContent = message;
  toastMessage.classList.add('show');
  window.clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => toastMessage.classList.remove('show'), 3000);
}

function setView(viewName) {
  const target = document.querySelector(`#view-${viewName}`);
  if (!target) return;
  document.querySelectorAll('.view-section').forEach((section) => section.classList.add('d-none'));
  target.classList.remove('d-none');
  document.querySelectorAll('.side-nav .nav-link').forEach((button) => {
    const selected = button.dataset.view === viewName;
    button.classList.toggle('active', selected);
    if (selected) button.setAttribute('aria-current', 'page');
    else button.removeAttribute('aria-current');
  });
  const pageTitle = target.dataset.title || 'Resumen';
  document.querySelector('#breadcrumbCurrent').textContent = pageTitle;
  document.title = `${pageTitle} · EduCore`;
  document.querySelector('#sidebar').classList.remove('open');
  document.querySelector('.sidebar-backdrop')?.remove();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function renderStudents(query = '') {
  const body = document.querySelector('#studentTableBody');
  if (!body) return;
  const normalizedQuery = query.trim().toLocaleLowerCase('es');
  const matched = students.filter((student) => `${student.name} ${student.email} ${student.career}`.toLocaleLowerCase('es').includes(normalizedQuery));
  const rows = matched.map((student) => {
    const row = document.createElement('tr');
    const personCell = document.createElement('td');
    const person = makeElement('div', 'table-person');
    person.append(makeElement('span', `avatar ${student.tone}`, student.initials));
    const details = makeElement('span');
    details.append(makeElement('strong', '', student.name), makeElement('small', '', student.email));
    person.append(details);
    personCell.append(person);
    const careerCell = makeElement('td', '', student.career);
    const coursesCell = makeElement('td', '', `${student.courses} cursos`);
    const attendanceCell = makeElement('td', '', `${student.attendance}%`);
    const statusCell = document.createElement('td');
    const status = makeElement('span', 'status-pill status-active');
    status.append(makeElement('i'), document.createTextNode('Activo'));
    statusCell.append(status);
    row.append(personCell, careerCell, coursesCell, attendanceCell, statusCell);
    return row;
  });
  body.replaceChildren(...rows);
  document.querySelector('#emptyStudents')?.classList.toggle('d-none', matched.length > 0);
}

function updateRole(role) {
  activeRole = role;
  const roleNames = { admin: 'Administradora', teacher: 'Docente', student: 'Estudiante' };
  const profileNames = { admin: ['María Cedeño', 'MC'], teacher: ['Andrea López', 'AL'], student: ['Javier Rodríguez', 'JR'] };
  const [name, initials] = profileNames[role] || profileNames.admin;
  document.querySelector('#sidebarRole').textContent = roleNames[role] || roleNames.admin;
  document.querySelectorAll('.profile-compact strong').forEach((element) => { element.textContent = name; });
  document.querySelectorAll('.profile-compact .avatar').forEach((element) => { element.textContent = initials; });
  document.querySelectorAll('.sidebar-user .avatar').forEach((element) => { element.textContent = initials; });
  document.querySelectorAll('.profile-compact small').forEach((element) => { element.textContent = roleNames[role] || roleNames.admin; });
  document.querySelectorAll('.admin-only').forEach((element) => element.classList.toggle('role-hidden', role !== 'admin'));
  renderCourses();
  document.querySelector('#addCourseButton')?.classList.toggle('d-none', role === 'student');
  document.querySelectorAll('[data-view-link="courses"]').forEach((button) => {
    button.classList.toggle('d-none', role === 'student' && button.classList.contains('button-primary'));
  });
  if (role !== 'admin' && document.querySelector('#view-users') && !document.querySelector('#view-users').classList.contains('d-none')) setView('dashboard');
  showToast(`Vista de demostración: ${roleNames[role] || roleNames.admin}.`);
}

courseSearch?.addEventListener('input', renderCourses);
statusFilter?.addEventListener('change', renderCourses);
document.querySelector('#studentSearch')?.addEventListener('input', (event) => renderStudents(event.target.value));
document.querySelector('#addCourseButton')?.addEventListener('click', () => openCourseDialog());
document.querySelector('#cancelCourseButton')?.addEventListener('click', () => courseDialog.close());
document.querySelector('#logoutButton')?.addEventListener('click', () => showToast('Prototipo: la sesión de demostración sigue activa.'));
document.querySelector('#roleSelect')?.addEventListener('change', (event) => updateRole(event.target.value));

courseForm?.addEventListener('submit', (event) => {
  event.preventDefault();
  if (!courseForm.reportValidity()) return;
  const existingId = document.querySelector('#courseId').value;
  const name = document.querySelector('#courseName').value.trim();
  const category = document.querySelector('#courseCategory').value;
  const teacher = document.querySelector('#courseTeacher').value.trim();
  const capacity = Number(document.querySelector('#courseCapacity').value);
  const status = document.querySelector('#courseStatus').value;
  if (!name || !teacher || !Number.isInteger(capacity) || capacity < 1) return;

  if (existingId) {
    const course = courses.find((item) => item.id === existingId);
    if (!course) return;
    Object.assign(course, { name, category, teacher, capacity, status });
    showToast('Los cambios del curso se guardaron localmente.');
  } else {
    const newId = `EDU-${String(Date.now()).slice(-6)}`;
    const iconByCategory = { Diseño: 'bi-bezier2', Tecnología: 'bi-code-slash', Ciencias: 'bi-calculator-fill', Humanidades: 'bi-chat-square-text-fill', Negocios: 'bi-kanban-fill' };
    courses.unshift({ id: newId, name, category, teacher, capacity, enrolled: 0, status, icon: iconByCategory[category] || 'bi-journal-bookmark-fill', tone: 'icon-mint' });
    showToast('Curso creado y guardado localmente.');
  }
  saveCourses();
  renderCourses();
  courseDialog.close();
});

document.querySelectorAll('[data-view]').forEach((button) => button.addEventListener('click', () => setView(button.dataset.view)));
document.querySelectorAll('[data-view-link]').forEach((button) => {
  button.addEventListener('click', () => {
    setView(button.dataset.viewLink);
    if (button.classList.contains('button-primary')) window.setTimeout(() => openCourseDialog(), 50);
  });
});
document.querySelectorAll('[data-toast]').forEach((button) => button.addEventListener('click', () => showToast(button.dataset.toast)));

document.querySelector('#menuToggle')?.addEventListener('click', () => {
  const sidebar = document.querySelector('#sidebar');
  sidebar.classList.toggle('open');
  if (sidebar.classList.contains('open')) {
    const backdrop = makeElement('div', 'sidebar-backdrop');
    backdrop.addEventListener('click', () => {
      sidebar.classList.remove('open');
      backdrop.remove();
    });
    document.body.append(backdrop);
  } else {
    document.querySelector('.sidebar-backdrop')?.remove();
  }
});

document.querySelector('#globalSearch')?.addEventListener('input', (event) => {
  const term = event.target.value.trim();
  if (!term) return;
  setView('courses');
  courseSearch.value = term;
  renderCourses();
});
document.addEventListener('keydown', (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault();
    document.querySelector('#globalSearch')?.focus();
  }
});

renderCourses();
renderStudents();
