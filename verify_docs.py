
import asyncio
from playwright.async_api import async_playwright

async def verify_docs():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        try:
            # Navigate to the GitHub Pages URL
            await page.goto("https://florisboard.github.io/florisboard/")

            # Wait for a specific element to be visible, indicating the page has loaded
            # I'll look for the Docusaurus title or a common header element
            await page.wait_for_selector("h1", timeout=10000) # Wait for any h1 element

            # Take a screenshot for visual verification
            await page.screenshot(path="docs_screenshot.png")
            print("Documentation page loaded successfully and screenshot taken.")

        except Exception as e:
            print(f"Error verifying documentation page: {e}")
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(verify_docs())
