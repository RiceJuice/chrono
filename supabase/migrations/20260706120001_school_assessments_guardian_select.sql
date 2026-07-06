-- Eltern dürfen Schul-Termine des Kindes lesen, wenn school freigegeben ist.
-- (SELECT-Policy ist bereits in 20260706120000_school_assessments.sql enthalten;
-- diese Datei dokumentiert die Guardian-Freigabe explizit für Review.)

COMMENT ON POLICY school_assessments_select_guardian_child ON public.school_assessments IS
  'Eltern-Lesezugriff wenn child_share_permissions.school = true.';
