const quoteBtn = document.getElementById("quoteBtn");
const result = document.getElementById("result");

quoteBtn.addEventListener("click", async () => {
  result.textContent = "Loading quote...";

  try {
    const response = await fetch("/api/quote");
    const data = await response.json();
    result.textContent = `"${data.quote}"`;
  } catch (error) {
    result.textContent = "Could not load quote.";
  }
});
