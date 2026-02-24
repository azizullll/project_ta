/**
 * Firebase Cloud Function untuk Password Reset
 * 
 * File ini harus ditempatkan di: functions/src/index.ts
 * atau functions/index.js (tergantung setup)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Cloud Function yang terpanggil ketika ada document baru
 * di collection 'password_reset_requests'
 */
exports.processPasswordReset = functions.firestore
  .document('password_reset_requests/{email}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const email = context.params.email;
    
    try {
      console.log(`Processing password reset for: ${email}`);
      
      // Get user by email
      const userRecord = await admin.auth().getUserByEmail(email);
      
      if (!userRecord) {
        console.error(`User not found: ${email}`);
        await snapshot.ref.update({
          status: 'failed',
          errorMessage: 'User not found',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }
      
      // Update user password
      await admin.auth().updateUser(userRecord.uid, {
        password: data.newPassword,
      });
      
      console.log(`Password updated successfully for: ${email}`);
      
      // Update status in Firestore
      await snapshot.ref.update({
        status: 'completed',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        newPassword: admin.firestore.FieldValue.delete(), // Remove password from storage
      });
      
      // Optional: Delete OTP document
      try {
        await admin.firestore()
          .collection('password_reset_otps')
          .doc(email)
          .delete();
      } catch (otpError) {
        console.log('OTP document already deleted or not found');
      }
      
      console.log(`Password reset completed for: ${email}`);
      
    } catch (error) {
      console.error('Error processing password reset:', error);
      
      // Update status to failed
      await snapshot.ref.update({
        status: 'failed',
        errorMessage: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * Alternative: HTTP Callable Function
 * Dapat dipanggil langsung dari Flutter app
 */
exports.updatePassword = functions.https.onCall(async (data, context) => {
  // Validate request
  if (!data.email || !data.newPassword || !data.resetToken) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }
  
  const { email, newPassword, resetToken } = data;
  
  try {
    // Verify reset token from Firestore
    const resetDoc = await admin.firestore()
      .collection('password_reset_requests')
      .doc(email)
      .get();
    
    if (!resetDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Reset request not found'
      );
    }
    
    const resetData = resetDoc.data();
    
    if (resetData.resetToken !== resetToken) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Invalid reset token'
      );
    }
    
    if (resetData.status === 'completed') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Password already reset'
      );
    }
    
    // Check if request is expired (30 minutes)
    const createdAt = resetData.createdAt.toDate();
    const now = new Date();
    const diffMinutes = (now - createdAt) / 1000 / 60;
    
    if (diffMinutes > 30) {
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'Reset request expired'
      );
    }
    
    // Get user and update password
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });
    
    // Update status
    await resetDoc.ref.update({
      status: 'completed',
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      newPassword: admin.firestore.FieldValue.delete(),
    });
    
    // Delete OTP
    await admin.firestore()
      .collection('password_reset_otps')
      .doc(email)
      .delete();
    
    return {
      success: true,
      message: 'Password updated successfully',
    };
    
  } catch (error) {
    console.error('Error in updatePassword:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to update password'
    );
  }
});

/**
 * Cleanup function - menghapus reset requests yang sudah expired
 * Dijadwalkan untuk berjalan setiap hari
 */
exports.cleanupExpiredResets = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const now = Date.now();
    const expiryTime = 30 * 60 * 1000; // 30 minutes
    
    const snapshot = await admin.firestore()
      .collection('password_reset_requests')
      .get();
    
    const batch = admin.firestore().batch();
    let count = 0;
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const createdAt = data.createdAt?.toDate().getTime() || 0;
      
      if (now - createdAt > expiryTime) {
        batch.delete(doc.ref);
        count++;
      }
    });
    
    if (count > 0) {
      await batch.commit();
      console.log(`Deleted ${count} expired password reset requests`);
    }
    
    return null;
  });
