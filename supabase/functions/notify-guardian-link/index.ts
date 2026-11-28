import { handleGuardianNotification } from "./handler.ts";

Deno.serve((request) => handleGuardianNotification(request));
