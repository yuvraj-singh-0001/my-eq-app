import {
  completeStudentGoal,
  createStudentGoal,
  findAssignedStudent,
  getStudentGoal,
  listStudentGoals,
  updateStudentGoalProgress,
} from '../../services/growth/goals.service.js';

export async function listGoals(request, response) {
  const student = await findAssignedStudent(request);
  const goals = await listStudentGoals(student, request.auth.sub, request.query.status);
  return response.json({ success: true, data: { goals } });
}

export async function createGoal(request, response) {
  const student = await findAssignedStudent(request);
  const goal = await createStudentGoal(request, student);
  return response.status(201).json({ success: true, data: { goal } });
}

export async function getGoal(request, response) {
  const student = await findAssignedStudent(request);
  const goal = await getStudentGoal(student, request.auth.sub, request.params.goalId);
  return response.json({ success: true, data: { goal } });
}

export async function updateGoalProgress(request, response) {
  const student = await findAssignedStudent(request);
  const result = await updateStudentGoalProgress(request, student);
  return response.json({ success: true, data: result });
}

export async function completeGoal(request, response) {
  const student = await findAssignedStudent(request);
  const goal = await completeStudentGoal(request, student);
  return response.json({ success: true, data: { goal } });
}
