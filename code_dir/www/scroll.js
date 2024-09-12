// Function to scroll to the bottom of a specified element
function scrollToBottom(elementId) {
  var element = document.getElementById(elementId);
  if (element) {
    element.scrollTop = element.scrollHeight;
  }
}

// Handle custom message from Shiny to trigger scrolling
Shiny.addCustomMessageHandler('scroll', function(message) {
  scrollToBottom(message.id);
});

document.getElementById('submit_question').addEventListener('click', function(event) {
    this.disabled = true;  // Disable the button on click
    setTimeout(() => { 
        this.disabled = false;  // Re-enable after some time if needed
    }, 5000);  // Adjust this delay as needed
});