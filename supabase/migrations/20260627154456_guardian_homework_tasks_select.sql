-- Eltern dürfen Hausaufgaben des Kindes lesen, wenn homework freigegeben ist.

DROP POLICY IF EXISTS homework_tasks_select_guardian_child ON public.homework_tasks;
CREATE POLICY homework_tasks_select_guardian_child ON public.homework_tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.guardian_child_links gcl
      WHERE gcl.guardian_id = auth.uid()
        AND gcl.child_id = homework_tasks.profile_id
        AND gcl.status = 'confirmed'
        AND COALESCE((gcl.child_share_permissions->>'homework')::boolean, false)
    )
  );
