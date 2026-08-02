describe('template spec', () => {
  it('Visits the Kitchen Sink', () => {
    // cy.visit(Cypress.env('TEST_URL'))https://example.cypress.io
    cy.visit(Cypress.env('TEST_URL'));

    cy.contains('type').click()

    cy.url().should('include', '/commands/actions')

    cy.get('.action-email').type('fake@email.com')

    cy.get('.action-email').should('have.value', 'fake@email.com')
  })
})