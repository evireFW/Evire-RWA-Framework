const AuditTrail = artifacts.require("AuditTrail");

const { expect } = require('chai');

contract('AuditTrail', (accounts) => {
  const [deployer, user1, user2] = accounts;

  let auditTrail;

  before(async () => {
    auditTrail = await AuditTrail.deployed();
  });

  describe('AuditTrail Contract', () => {
    it('should deploy successfully', async () => {
      expect(auditTrail.address).to.not.be.oneOf([0x0, '', null, undefined]);
    });

    it('should create a new audit event', async () => {
      const tx = await auditTrail.createAuditEvent('Asset Created', 'Asset ID: 123', { from: user1 });
      expect(tx.logs[0].event).to.equal('AuditEventCreated');
    });

    it('should store audit events correctly', async () => {
      await auditTrail.createAuditEvent('Ownership Transferred', 'From User1 to User2', { from: user1 });
      const eventCount = await auditTrail.getAuditEventCount();
      expect(eventCount.toNumber()).to.equal(2);
    });

    it('should retrieve audit event details correctly', async () => {
      const auditEvent = await auditTrail.getAuditEvent(0);
      expect(auditEvent[0]).to.equal('Asset Created');
      expect(auditEvent[1]).to.equal('Asset ID: 123');
      expect(auditEvent[2]).to.equal(user1);
    });

    it('should not allow unauthorized users to create audit events', async () => {
      try {
        await auditTrail.createAuditEvent('Unauthorized Event', 'Should Fail', { from: user2 });
        assert.fail('Expected throw not received');
      } catch (error) {
        assert(error.message.indexOf('revert') >= 0, 'Expected revert error not received');
      }
    });

    it('should return correct events for an address', async () => {
      const user1Events = await auditTrail.getEventsByAddress(user1);
      expect(user1Events.length).to.equal(2);

      const user2Events = await auditTrail.getEventsByAddress(user2);
      expect(user2Events.length).to.equal(0);
    });

    it('should correctly log events in chronological order', async () => {
      const auditEvent1 = await auditTrail.getAuditEvent(0);
      const auditEvent2 = await auditTrail.getAuditEvent(1);
      expect(new Date(auditEvent1[3] * 1000)).to.be.below(new Date(auditEvent2[3] * 1000));
    });
  });
});
