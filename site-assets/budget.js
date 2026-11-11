const form = document.querySelector("#budget-form");
const inputs = [...form.querySelectorAll("input")];
const total = document.querySelector("#budget-total");
const detail = document.querySelector("#budget-detail");
const currency = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });

function updateSubtotal() {
  const entered = inputs.filter((input) => input.value !== "" && input.validity.valid);
  const cents = entered.reduce((sum, input) => sum + Math.round(input.valueAsNumber * 100), 0);
  total.textContent = currency.format(cents / 100);
  detail.textContent = entered.length + " of " + inputs.length + " line items priced";
}

form.addEventListener("input", updateSubtotal);
form.addEventListener("reset", () => requestAnimationFrame(updateSubtotal));
form.addEventListener("submit", (event) => event.preventDefault());
updateSubtotal();
