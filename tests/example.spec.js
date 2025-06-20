// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Example Tests', () => {
  test('has title', async ({ page }) => {
    await page.goto('https://playwright.dev/');
    
    // Expect a title "to contain" a substring.
    await expect(page).toHaveTitle(/Playwright/);
  });

  test('get started link', async ({ page }) => {
    await page.goto('https://playwright.dev/');

    // Click the get started link.
    await page.getByRole('link', { name: 'Get started' }).click();

    // Expects page to have a heading with the name of Installation.
    await expect(page.getByRole('heading', { name: 'Installation' })).toBeVisible();
  });
});

test.describe('API Testing Example', () => {
  test('should create a TODO item', async ({ request }) => {
    const newTodo = await request.post('https://jsonplaceholder.typicode.com/todos', {
      data: {
        title: 'Learn Playwright',
        completed: false,
        userId: 1
      }
    });
    
    expect(newTodo.ok()).toBeTruthy();
    expect(await newTodo.json()).toEqual(expect.objectContaining({
      title: 'Learn Playwright',
      completed: false,
      userId: 1
    }));
  });
});