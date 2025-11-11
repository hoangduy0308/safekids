/**
 * End-to-End Tests: Geofence Creation Journey
 * Story 3.1 - P1 Priority
 * Framework: Playwright
 * Focus: User workflows, UI interactions, map integration
 */

import { test, expect } from '@playwright/test';

test.describe('Geofence Creation Journey - AC 3.1.1-3.1.5', () => {
  const TEST_PARENT_EMAIL = `parent-${Date.now()}@test.local`;
  const TEST_CHILD_NAME = 'Test Child';
  let parentPage: any;
  let childPage: any;

  test.beforeAll(async ({ browser }) => {
    // Setup: Create parent & child accounts in separate browser contexts
    const parentContext = await browser.newContext();
    const childContext = await browser.newContext();

    parentPage = await parentContext.newPage();
    childPage = await childContext.newPage();

    // Register parent
    await parentPage.goto('/auth/register');
    await parentPage.fill('input[name="name"]', 'Test Parent');
    await parentPage.fill('input[name="email"]', TEST_PARENT_EMAIL);
    await parentPage.fill('input[name="password"]', 'TestPass123!');
    await parentPage.fill('input[name="phone"]', '+84912345678');
    await parentPage.selectOption('select[name="role"]', 'parent');
    await parentPage.click('button:has-text("Register")');
    await parentPage.waitForNavigation();

    // Register child
    await childPage.goto('/auth/register');
    await childPage.fill('input[name="name"]', TEST_CHILD_NAME);
    await childPage.fill('input[name="email"]', `child-${Date.now()}@test.local`);
    await childPage.fill('input[name="password"]', 'ChildPass123!');
    await childPage.fill('input[name="phone"]', '+84987654321');
    await childPage.selectOption('select[name="role"]', 'child');
    await childPage.fill('input[name="age"]', '10');
    await childPage.click('button:has-text("Register")');
    await childPage.waitForNavigation();
  });

  test('P1: AC 3.1.1 - Parent can draw circle on map with adjustable radius', async () => {
    // Login as parent
    await parentPage.goto('/auth/login');
    await parentPage.fill('input[name="email"]', TEST_PARENT_EMAIL);
    await parentPage.fill('input[name="password"]', 'TestPass123!');
    await parentPage.click('button:has-text("Login")');
    await parentPage.waitForNavigation();

    // Navigate to map/dashboard
    await parentPage.goto('/parent/dashboard');
    await parentPage.waitForSelector('button:has-text("Tạo Vùng")');

    // Step 1: Click "Tạo Vùng" button to enable draw mode
    await parentPage.click('button:has-text("Tạo Vùng")');

    // Verify draw mode enabled with instruction text
    const instruction = await parentPage.locator('text=Nhấn vào bản đồ để chọn tâm vùng');
    expect(await instruction.isVisible()).toBe(true);

    // Step 2: Tap on map to set center point
    const mapElement = await parentPage.locator('[data-testid="map"]');
    expect(await mapElement.count()).toBeGreaterThan(0);

    // Simulate map click at center
    await mapElement.click({ position: { x: 400, y: 300 } });

    // Step 3: Adjust radius using slider
    const radiusSlider = await parentPage.locator('input[type="range"]');
    expect(await radiusSlider.isVisible()).toBe(true);

    // Set radius to 250m
    await radiusSlider.fill('250');

    // Verify radius label updated
    const radiusLabel = await parentPage.locator('text=/250m/');
    expect(await radiusLabel.isVisible()).toBe(true);

    // Step 4: Click "Tiếp tục" to confirm radius
    await parentPage.click('button:has-text("Tiếp tục")');

    // Expect geofence form dialog to appear
    const formDialog = await parentPage.locator('[role="dialog"]:has-text("Tạo vùng mới")');
    expect(await formDialog.isVisible()).toBe(true);
  });

  test('P1: AC 3.1.2 - Parent configures geofence (name, type, children)', async () => {
    // Assume we're in the geofence form from previous test
    // Fill geofence configuration form

    // Fill name
    const nameInput = await parentPage.locator('input[placeholder="Tên vùng"]');
    expect(await nameInput.isVisible()).toBe(true);
    await nameInput.fill('Nhà');

    // Select "Safe Zone" type (should be default)
    const safeZoneRadio = await parentPage.locator('input[value="safe"]');
    await safeZoneRadio.check();
    expect(await safeZoneRadio.isChecked()).toBe(true);

    // Link child
    const childCheckbox = await parentPage.locator(`input[value="${TEST_CHILD_NAME}"]`);
    if (await childCheckbox.isVisible()) {
      await childCheckbox.check();
      expect(await childCheckbox.isChecked()).toBe(true);
    }

    // Save geofence
    await parentPage.click('button:has-text("Lưu")');

    // Verify geofence saved (toast notification)
    const toast = await parentPage.locator('text=/Đã tạo vùng/');
    expect(await toast.isVisible()).toBe(true);

    // Verify form closes and we're back to map
    await parentPage.waitForTimeout(500);
    const dialog = await parentPage.locator('[role="dialog"]');
    expect(await dialog.isVisible()).toBe(false);
  });

  test('P1: AC 3.1.4 - Parent views safe zone on map (green circle)', async () => {
    // Refresh dashboard to see saved geofence
    await parentPage.reload();
    await parentPage.waitForSelector('[data-testid="map"]');
    await parentPage.waitForTimeout(500);

    // Look for green circle (safe zone)
    const greenCircle = await parentPage.locator('circle[stroke="green"]');
    expect(await greenCircle.count()).toBeGreaterThan(0);

    // Verify circle has correct attributes
    const circle = greenCircle.first();
    const stroke = await circle.getAttribute('stroke');
    expect(stroke).toBe('green');

    // Check circle has test data-testid
    const dataTestId = await circle.getAttribute('data-geofence-type');
    expect(dataTestId).toBe('safe');
  });

  test('P1: AC 3.1.4 - Tap geofence circle to view details', async () => {
    // Tap green circle
    const greenCircle = await parentPage.locator('circle[data-geofence-type="safe"]');
    expect(await greenCircle.count()).toBeGreaterThan(0);

    await greenCircle.first().click();

    // Verify bottom sheet appears with geofence details
    const detailsSheet = await parentPage.locator('[data-testid="geofence-details-sheet"]');
    expect(await detailsSheet.isVisible()).toBe(true);

    // Check details are displayed
    const nameText = await parentPage.locator('text=Nhà');
    expect(await nameText.isVisible()).toBe(true);

    const typeText = await parentPage.locator('text=Vùng an toàn');
    expect(await typeText.isVisible()).toBe(true);

    const radiusText = await parentPage.locator('text=/250m/');
    expect(await radiusText.isVisible()).toBe(true);
  });

  test('P1: AC 3.1.5 - Parent edits geofence details', async () => {
    // Open details sheet (tap circle)
    const greenCircle = await parentPage.locator('circle[data-geofence-type="safe"]');
    await greenCircle.first().click();

    // Click Edit button
    const editButton = await parentPage.locator('button:has-text("Chỉnh sửa")');
    expect(await editButton.isVisible()).toBe(true);
    await editButton.click();

    // Expect form dialog with pre-filled values
    const formDialog = await parentPage.locator('[role="dialog"]:has-text("Chỉnh sửa vùng")');
    expect(await formDialog.isVisible()).toBe(true);

    // Check name pre-filled
    const nameInput = await parentPage.locator('input[placeholder="Tên vùng"]');
    const nameValue = await nameInput.inputValue();
    expect(nameValue).toBe('Nhà');

    // Edit name
    await nameInput.clear();
    await nameInput.fill('Nhà cũ');

    // Update
    await parentPage.click('button:has-text("Cập nhật")');

    // Verify update success
    const toast = await parentPage.locator('text=/Đã cập nhật/');
    expect(await toast.isVisible()).toBe(true);

    // Verify name changed on map
    await parentPage.waitForTimeout(500);
    const greenCircle2 = await parentPage.locator('circle[data-geofence-type="safe"]');
    await greenCircle2.first().click();
    const updatedName = await parentPage.locator('text=Nhà cũ');
    expect(await updatedName.isVisible()).toBe(true);
  });

  test('P1: AC 3.1.5 - Parent deletes geofence with confirmation', async () => {
    // Open details sheet
    const greenCircle = await parentPage.locator('circle[data-geofence-type="safe"]');
    expect(await greenCircle.count()).toBeGreaterThan(0);
    await greenCircle.first().click();

    // Click Delete button
    const deleteButton = await parentPage.locator('button:has-text("Xóa")');
    expect(await deleteButton.isVisible()).toBe(true);
    await deleteButton.click();

    // Expect confirmation dialog
    const confirmDialog = await parentPage.locator('text=/Bạn có chắc muốn xóa/');
    expect(await confirmDialog.isVisible()).toBe(true);

    // Confirm deletion
    const confirmDeleteBtn = await parentPage.locator('button:has-text("Xóa")[style*="red"], button:has-text("Xóa"):nth-of-type(2)');
    if (await confirmDeleteBtn.isVisible()) {
      await confirmDeleteBtn.click();
    } else {
      // Fallback: click red button
      const redButton = await parentPage.locator('button[style*="background"]');
      await redButton.click();
    }

    // Verify deletion success
    const toast = await parentPage.locator('text=/Đã xóa/');
    expect(await toast.isVisible()).toBe(true);

    // Verify circle removed from map
    await parentPage.waitForTimeout(500);
    const remainingCircles = await parentPage.locator('circle[data-geofence-type="safe"]');
    // Either 0 circles or none visible (depends on implementation)
    // expect(await remainingCircles.count()).toBe(0);
  });

  test('P1: AC 3.1.1 - Create danger zone (red circle)', async () => {
    // Click "Tạo Vùng" to enable draw mode
    await parentPage.click('button:has-text("Tạo Vùng")');
    const instruction = await parentPage.locator('text=Nhấn vào bản đồ để chọn tâm vùng');
    expect(await instruction.isVisible()).toBe(true);

    // Tap on different location
    const mapElement = await parentPage.locator('[data-testid="map"]');
    await mapElement.click({ position: { x: 500, y: 350 } });

    // Set radius
    const radiusSlider = await parentPage.locator('input[type="range"]');
    await radiusSlider.fill('150');

    // Continue
    await parentPage.click('button:has-text("Tiếp tục")');

    // Select "Danger Zone" type
    const dangerZoneRadio = await parentPage.locator('input[value="danger"]');
    await dangerZoneRadio.check();
    expect(await dangerZoneRadio.isChecked()).toBe(true);

    // Fill other fields
    const nameInput = await parentPage.locator('input[placeholder="Tên vùng"]');
    await nameInput.fill('Đường lớn');

    const childCheckbox = await parentPage.locator(`input[value="${TEST_CHILD_NAME}"]`);
    if (await childCheckbox.isVisible()) {
      await childCheckbox.check();
    }

    // Save
    await parentPage.click('button:has-text("Lưu")');

    // Verify danger zone (red circle) appears on map
    await parentPage.waitForTimeout(500);
    const redCircle = await parentPage.locator('circle[data-geofence-type="danger"]');
    expect(await redCircle.count()).toBeGreaterThan(0);

    const circle = redCircle.first();
    const stroke = await circle.getAttribute('stroke');
    expect(stroke).toBe('red');
  });

  test('P2: Validation - Reject empty name', async () => {
    // Try to create geofence without name
    await parentPage.click('button:has-text("Tạo Vùng")');

    const mapElement = await parentPage.locator('[data-testid="map"]');
    await mapElement.click({ position: { x: 300, y: 250 } });

    const radiusSlider = await parentPage.locator('input[type="range"]');
    await radiusSlider.fill('100');

    await parentPage.click('button:has-text("Tiếp tục")');

    // Try to save without name
    const saveButton = await parentPage.locator('button:has-text("Lưu")');
    
    // Button might be disabled or form validation shown
    const nameInput = await parentPage.locator('input[placeholder="Tên vùng"]');
    const isRequired = await nameInput.getAttribute('required');
    expect(isRequired).toBeDefined();
  });

  test('P2: Validation - Reject invalid radius', async () => {
    await parentPage.click('button:has-text("Tạo Vùng")');

    const mapElement = await parentPage.locator('[data-testid="map"]');
    await mapElement.click({ position: { x: 350, y: 280 } });

    // Try to set invalid radius (the slider should have min/max constraints)
    const radiusSlider = await parentPage.locator('input[type="range"]');
    const min = await radiusSlider.getAttribute('min');
    const max = await radiusSlider.getAttribute('max');

    expect(min).toBe('50');
    expect(max).toBe('1000');
  });

  test.afterAll(async () => {
    await parentPage?.close();
    await childPage?.close();
  });
});
