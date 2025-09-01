document.addEventListener('DOMContentLoaded', function() {
  const currentPath = window.location.pathname;
  
  // Define menu mappings
  const menuMappings = {
    'git_connector': 'a[href*="git_connector"]',
    // Add other menu items here as needed
    // 'other_controller': 'a[href*="other_controller"]'
  };
  
  // Check each mapping
  Object.keys(menuMappings).forEach(path => {
    if (currentPath.includes(path)) {
      const menuItem = document.querySelector(menuMappings[path]);
      if (menuItem) {
        menuItem.classList.add('selected');
      }
    }
  });
});