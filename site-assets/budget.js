const form = document.querySelector("#budget-form");
const inputs = [...form.querySelectorAll("input")];
const total = document.querySelector("#budget-total");
const detail = document.querySelector("#budget-detail");
const tax = document.querySelector("#budget-tax");
const amazonTaxPercent = 8;
const currency = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });

function updateSubtotal() {
  const entered = inputs.filter((input) => input.value !== "" && input.validity.valid);
  let cents = 0;
  let taxCents = 0;
  for (const input of entered) {
    const lineCents = Math.round(input.valueAsNumber * 100);
    cents += lineCents;
    if (input.hasAttribute("data-amazon-tax")) {
      taxCents += Math.round(lineCents * amazonTaxPercent / 100);
    }
  }
  total.textContent = currency.format((cents + taxCents) / 100);
  tax.textContent = "Includes " + currency.format(taxCents / 100) + " estimated Amazon sales tax";
  detail.textContent = entered.length + " of " + inputs.length + " line items priced";
}

form.addEventListener("input", updateSubtotal);
form.addEventListener("reset", () => requestAnimationFrame(updateSubtotal));
form.addEventListener("submit", (event) => event.preventDefault());
updateSubtotal();
