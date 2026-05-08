// Cloud Functions entry point. Re-export each function from
// src/functions/ — the deploy step picks them up by name.

export { createOrder } from "./functions/createOrder";
export { payhereNotify } from "./functions/payhereNotify";
export { onOrderCreate } from "./functions/onOrderCreate";
export { onOrderStatusChange } from "./functions/onOrderStatusChange";
export { setManagerRole } from "./functions/setManagerRole";
