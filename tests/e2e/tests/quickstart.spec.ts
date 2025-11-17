//========================================================================
// Copyright Universidade Federal do Espirito Santo (Ufes)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// This program is released under license GNU GPL v3+ license.
//
//========================================================================

import { test, expect } from '@playwright/test';

test.describe.serial('Test scenarios', () => {
  test.beforeEach(async ({ page }) => {
    // Go to the starting url before each test
    await page.goto('/relax');
  });

  test.describe('Positive testing', () => {
    test('Has title', async ({ page }) => {
      // Expect a title "to contain" a substring
      await expect(page).toHaveTitle(/RelaX/);
    });

    test('Has text', async ({ page }) => {
      // Expect page "to contain" a string
      await expect(
        page.getByText('RelaX - relational algebra calculator') !== undefined
      ).toBeTruthy();
    });

    test('Get started', async ({ page }) => {
      // Click the get started button
      await page.getByRole('button', { name: 'Get Started' }).click();

      // Expect page "to contain" button
      await expect(
        page.getByRole('button', { name: 'execute query' }) !== undefined
      ).toBeTruthy();

      // Run query
      await page.getByRole('button').filter({ hasText: 'Select DB' }).click();
      await page.getByRole('link', { name: 'UIBK - R, S, T' }).click();
      await page.locator('.CodeMirror-scroll').first().click();
      await page.getByRole('textbox').fill('R join S join T');
      await page.getByRole('button', { name: 'execute query' }).click();

      // Check tuples
      await expect(page.getByText("1'a''d'100") !== undefined).toBeTruthy();
      await expect(page.getByText("4'd''f'200") !== undefined).toBeTruthy();
      await expect(page.getByText("5'd''b'200") !== undefined).toBeTruthy();
    });
  });
});
